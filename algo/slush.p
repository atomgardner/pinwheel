enum Colour { None, Red, Green }

machine Slusher {
	// node id
	var id: int;
	// this nodes colour
	var colour: Colour;
	// network/swarm
	var peers: set[machine];
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
					counts = newCounter();
					send c.source, Ready;
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
			var slusher: machine;
			var sample: set[machine];

			round = round + 1;
			counts = newCounter();
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
					goto Accepted;
				}
			}
		}
		on Query do (r: QueryRequest) {
			send r.source, Response, (source = this, colour = colour);
		}
	}

	state Accepted {
		entry {
			if (txSrc != null) {
				send txSrc, Accept, (source = this, colour = colour);
			}
		}
		on Transaction do (r: TxRequest) {
			send r.source, Accept, (source = this, colour = colour);
		}
		on Query do (r: QueryRequest) {
			send r.source, Response, (source = this, colour = colour);
		}
	}
}

fun newCounter(): map[Colour, int] {
	var c: map[Colour, int];
	c[None] = 0;
	c[Red] = 0;
	c[Green] = 0;
	return c;
}
