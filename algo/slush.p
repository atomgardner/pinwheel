enum Colour { None, Red, Green }

event Setup: Config;

event Transaction: TxRequest;
event Accept: TxResponse;
event Query: QueryRequest;
event Response: QueryResponse;

type TxRequest = (source: machine, colour: Colour);
type TxResponse = (source: machine, colour: Colour);
type QueryRequest = (source: machine, colour: Colour);
type QueryResponse = (source: machine, colour: Colour);
type Config = (id: int, peers: set[Slusher]);

fun resetCounts(): map[Colour, int] {
	var c: map[Colour, int];
	c[None] = 0;
	c[Red] = 0;
	c[Green] = 0;
	return c;
}

machine Slusher {
	// node id
	var id: int;
	// this nodes colour
	var colour: Colour;
	// network/swarm
	var peers: set[Slusher];
	// sample size
	var k: int;
	// number of rounds
	var m: int;
	// client that initiated the transaction
	var txSrc: machine;
	// the query round counter
	var round: int;
	// counts for query responses
	var counts: map[Colour, int];
	// number of responses collected
	var responses: int;

	start state Init {
		defer Transaction, Query;

		entry {
			receive {
				case Setup: (c: Config) {
					id = c.id;
					peers = c.peers;
					colour = None;

					k = sizeof(peers)/2 + 1;
					m = 10;
					counts = resetCounts();
				}
			}

			goto Listen;
		}
	}

	state Listen {
		on Transaction do (r: TxRequest) {
			txSrc = r.source;
			// Upon receiving a transaction from a client, an uncolored node
			// updates its own color to the one carried in the transaction
			// and initiates a query
			if (colour == None) {
				colour = r.colour;
				goto InitiateQuery;
			}

			send r.source, Accept, (source = this, colour = colour);
			goto Listen;
		}

		on Query do (r: QueryRequest) {
			if (colour == None) {
				colour = r.colour;
				send r.source, Response, (source = this, colour = colour);
				goto InitiateQuery;
			}

			send r.source, Response, (source = this, colour = colour);
			goto Listen;
		}
	}

	state InitiateQuery {
		defer Transaction;

		entry {
			var slusher: Slusher;
			var sample: set[Slusher];

			round = round + 1;
			counts = resetCounts();
			responses = 0;

			while (sizeof(sample) < k) {
				slusher = (choose(peers));
				if (slusher == this) {
					continue;
				}
				sample += (slusher);
			}

			foreach (slusher in sample) {
				send slusher, Query, (source = this, colour = colour);
			}

			goto Querying;
		}
	}

	state Querying {
		defer Transaction;

		on Response do (r: QueryResponse) {
			responses = responses + 1;
			counts[r.colour] = counts[r.colour] + 1;

			// message delivery is guaranteed
			if (responses == k) {
				if (counts[Green] > k/2) {
                                        print format("{0} changed colour to Green", this);
					colour = Green;
				}
				if (counts[Red] > k/2) {
                                        print format("{0} changed colour to Red", this);
					colour = Red;
				}

				if (round < m) {
					goto InitiateQuery;
				} else {
					if (txSrc != null) {
						send txSrc, Accept, (source = this, colour = colour);
					}
					goto Accepted;
				}
			}
		}
		on Query do (r: QueryRequest) {
			send r.source, Response, (source = this, colour = colour);
		}
	}

	state Accepted {
		on Transaction do (r: TxRequest) {
			send r.source, Accept, (source = this, colour = colour);
		}
		on Query do (r: QueryRequest) {
			send r.source, Response, (source = this, colour = colour);
		}
	}
}
