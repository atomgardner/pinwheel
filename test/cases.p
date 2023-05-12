test SlushSingleClient [main=TestWithSingleClient]:
        assert AtLeastOneAccept
        in (union Client, { Slusher -> Node }, { TestWithSingleClient });

test SlushMultiClient [main=TestWithVirtuousClients]:
        assert AtLeastOneAccept, Consensus
        in (union Client, { Slusher -> Node }, { TestWithVirtuousClients });

test SnowflakeSingleClient [main=TestWithSingleClient]:
        assert AtLeastOneAccept
        in (union Client, { Snowflaker -> Node }, { TestWithSingleClient });

test SnowflakeMultiClient [main=TestWithVirtuousClients]:
        assert AtLeastOneAccept, Consensus
        in (union Client, { Snowflaker -> Node }, { TestWithVirtuousClients });

test SnowballSingleClient [main=TestWithSingleClient]:
        assert AtLeastOneAccept
        in (union Client, { Snowballer -> Node }, { TestWithSingleClient });

test SnowballMultiClient [main=TestWithVirtuousClients]:
        assert AtLeastOneAccept, Consensus
        in (union Client, { Snowballer -> Node }, { TestWithVirtuousClients });
