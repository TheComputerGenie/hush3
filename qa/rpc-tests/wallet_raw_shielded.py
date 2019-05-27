#!/usr/bin/env python2
# Copyright (c) 2018 The Zcash developers
# Copyright (c) 2019 The Hush developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

from test_framework.test_framework import BitcoinTestFramework
from test_framework.util import assert_equal, start_nodes, wait_and_assert_operationid_status
from decimal import Decimal

class WalletRawShielded(BitcoinTestFramework):

    def setup_nodes(self):
        return start_nodes(4, self.options.tmpdir, [[
            '-nuparams=5ba81b19:202', # Overwinter
            '-nuparams=76b809bb:204', # Sapling
        ]] * 4)

    def run_test(self):
        # Current height = 200 -> Sprout
        alice = self.nodes[0]
        assert_equal(200, alice.getblockcount())

        # test that we can create a sapling zaddr before sapling activates
        zaddr = alice.z_getnewaddress('sapling')

        # we've got lots of coinbase (taddr) but no shielded funds yet
        assert_equal(0, Decimal(alice.z_gettotalbalance()['private']))

        # Current height = 202 -> Overwinter. Default address type remains Sprout
        alice.generate(2)
        self.sync_all()
        assert_equal(202, alice.getblockcount())

        mining_addr = alice.listunspent()[0]['address']

        # Shield coinbase funds
        receive_amount_10 = Decimal('10.0') - Decimal('0.0001')
        recipients        = [{"address":zaddr, "amount":receive_amount_10}]
        myopid            = alice.z_sendmany(mining_addr, recipients)
        txid1             = wait_and_assert_operationid_status(alice, myopid)
        self.sync_all()

        # Generate a block to confirm shield coinbase tx
        alice.generate(1)
        self.sync_all()

        assert_equal(203, alice.getblockcount())
        newzaddr = alice.z_getnewaddress('sapling')

        # Simplest test: one input and one output, no change
        inputs  = [ {"txid":txid, "outindex": 0, "address": zaddr } ]
        outputs = [ {"address":newzaddr, "amount": 9.9999 } ]
        rawhex  = alice.z_createrawtransaction(inputs,outputs)
        print(rawhex)

if __name__ == '__main__':
    WalletRawShielded().main()
