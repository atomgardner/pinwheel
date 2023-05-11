event Setup: Config;
event Ready;
type Config = (source: machine, id: int, peers: set[machine]);

event Transaction: TxRequest;
event Accept: TxResponse;
event Query: QueryRequest;
event Response: QueryResponse;

type TxRequest = (source: machine, colour: Colour);
type TxResponse = (source: machine, colour: Colour);
type QueryRequest = (source: machine, colour: Colour);
type QueryResponse = (source: machine, colour: Colour);
