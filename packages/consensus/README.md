# Bitcoin consensus in Cairo

This package is a Cairo library providing primitives for validating Bitcoin consensus.  

It is structured as follows:
* `types` module contains all Bitcoin specific entities (start your codebase tour with this folder) adapted for recursive verification;
* `validation` module contains most of the consensus validation logic;
* `codec` module contains implementation of Bitcoin binary codec for transaction types.
