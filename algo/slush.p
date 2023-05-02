enum Colour { Red, Green, None }

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

machine Slusher {
	var id: int;
	var colour: Colour;
	var peers: set[Slusher];
	var k: int; // safety
	var m: int; // number of rounds

	var round: int;
	var counts: map[Colour, int];

	start state Init {
		defer Transaction, Query;

		entry {
			receive {
				case Setup: (c: Config) {
					id = c.id;
					peers = c.peers;
					k = sizeof(peers)/2 + 1;
					m = 10;
				}
			}

			goto Listen;
		}
	}

	state Listen {
		on Transaction do (r: TxRequest) {
			// Upon receiving a transaction from a client, an uncolored node
			// updates its own color to the one carried in the transaction
			// and initiates a query
			if (colour to int == None to int ) {
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
			while (sizeof(sample) < k) {
				sample += (choose(peers));
			}

			foreach (slusher in sample) {
				send slusher, Query, (source = this, colour = colour);
			}

			goto Querying;
		}
	}

	state Querying {
		defer Transaction;

		entry {
			if (round == m) {
				goto Accepted;
			}
		}

		on Response do (r: QueryResponse) {
			counts[r.colour] = counts[r.colour] + 1;

			// message delivery is guaranteed
			if (sizeof(counts) == k) {
				if (counts[Green] > k/2) {
					colour = Green;
				}
				if (counts[Red] > k/2) {
					colour = Red;
				}

				round = round + 1;
				counts = default(map[Colour, int]);

				goto Querying;
			}
		}

		on Query do (r: QueryRequest) {
			send r.source, Response, (source = this, colour = colour);
		}
	}

	state Accepted {
		on Transaction do (r: TxRequest) {
			send r.source, Response, (source = this, colour = colour);
		}
		on Query do (r: QueryRequest) {
			send r.source, Response, (source = this, colour = colour);
		}
	}
}
