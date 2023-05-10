test SingleClient [main=TestWithSingleClient]:
        assert AtLeastOneAccept
        in (union Client, Slusher, { TestWithSingleClient });

test MultiClient [main=TestWithVirtuousClients]:
        assert AtLeastOneAccept, Consensus
        in (union Client, Slusher, { TestWithVirtuousClients });
