machine Snowballer {
	// The node colour
	var colour: Colour;
	// The client that initiated the transaction
	var txSrc: machine;
	// The peers attached to this node
	var peers: set[machine];

	// The least number of responses required to win a query
	var alpha: int;
	// The number of consecutive queries a colour must win for the node to
	// decide that colour
	var beta: int;

	// counts for present query responses
	var counts: map[Colour, int];
	// query sample size
	var k: int;
	// wins tracks the number of queries a colour has won. The node value
	// tracks the colour that's won more queries
	var wins: map[Colour, int];
	// colours may now win the query without the node value changing, and so
	// we must remember which colour last won and the length of its win
	// streak
	var most_recent_winner: Colour;
	// The number of consecutive wins for the most recent winner.
	var chits: int;

	start state Init {
		entry {
			receive {
				case Setup: (c: Config) {
					peers = c.peers;
					beta = 2*sizeof(peers);
					k = sizeof(peers)/2 + 1;
					alpha = k/2 + 1;
					counts = newCounter();
					wins[Red] = 0;
					wins[Green] = 0;
					send c.source, Ready;
				}
			}
			goto Listen;
		}
	}

	state Listen {
		on Transaction do (r: TxRequest) {
			colour = r.colour;
			txSrc = r.source;
			goto InitiateQuery;
		}
		on Query do (r: QueryRequest) {
			colour = r.colour;
			send r.source, Response,
			     (source = this, colour = colour);
			goto InitiateQuery;
		}
	}

	fun query_random_neighbourhood(peers: set[machine], sample_size: int) {
		var m: machine;
		var sample: set[machine];

		while (sizeof(sample) < sample_size) {
			m = (choose(peers));
			if (m == this) {
				continue;
			}
			sample += (m);
		}

		foreach (m in sample) {
			send m, Query, (source = this, colour = colour);
		}
	}

	state InitiateQuery {
		entry {
			counts = newCounter();

			query_random_neighbourhood(peers, k);

			goto Querying;
		}
	}

	state Querying {
		defer Transaction;

		on Response do (r: QueryResponse) {
			counts[r.colour] = counts[r.colour] + 1;
			if (counts[Red] + counts[Green] == k) {
				goto Deciding;
			}
		}

		on Query do (r: QueryRequest) {
			send r.source, Response,
				(source = this, colour = colour);
		}
	}

	state Deciding {
		entry {
			var above_alpha: bool;
			var col: Colour;
			var cols: set[Colour];

			above_alpha = false;
			cols += (Green);
			cols += (Red);

			foreach (col in cols) {
				if (counts[col] >= alpha) {
					above_alpha = true;
					wins[col] = wins[col] + 1;
					if (wins[col] > wins[colour]) {
						colour = col;
					}
					if (col != most_recent_winner) {
						most_recent_winner = col;
						chits = 1;
					} else {
						chits = chits + 1;
					}
					if (chits >= beta) {
						goto Decided;
					}
				}
			}
			if (!above_alpha) {
				chits = 0;
			}
			goto InitiateQuery;
		}
	}

	state Decided {
		entry {
			if (txSrc != null) {
				send txSrc, Accept,
				     (source = this, colour = colour);
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
