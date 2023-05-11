test SlushSingleClient [main=TestWithSingleClient]:
        assert AtLeastOneAccept
        in (union Client, { Slusher -> Node }, { TestWithSingleClient });

test SlushMultiClient [main=TestWithVirtuousClients]:
        assert AtLeastOneAccept, Consensus
        in (union Client, { Slusher -> Node }, { TestWithVirtuousClients });
