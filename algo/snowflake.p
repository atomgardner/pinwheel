machine Snowflaker {
	// the node colour
	var colour: Colour;
	// client that initiated the transaction
	var txSrc: machine;
	// counts for present query responses
	var counts: map[Colour, int];
	// query sample size
	var k: int;
	// number of responses to the present query
	var n_responses: int;
	// confidence tracks the number of consequtive queries a colour has won;
	// a node will accept when confidence goes above β.
	var confidence: int;
	var alpha: int;
	var beta: int;
	var peers: set[machine];

	start state Init {
		entry {
			receive {
				case Setup: (c: Config) {
					peers = c.peers;
					alpha = k/2 + 1;
					beta = sizeof(peers);
					k = sizeof(peers)/2 + 1;
					counts = newCounter();

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
			n_responses = 0;

			query_random_neighbourhood(peers, k);

			goto Querying;
		}
	}

	state Querying {
		defer Transaction;

		on Response do (r: QueryResponse) {
			counts[r.colour] = counts[r.colour] + 1;
                        n_responses = n_responses + 1;
			if (n_responses == k) {
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
			var oldColour: Colour;

			above_alpha = false;
			oldColour = colour;

			if (counts[Green] >= alpha) {
				above_alpha = true;
				colour = Green;
			}
			if (counts[Red] >= alpha) {
				above_alpha = true;
				colour = Red;
			}

			if (colour == oldColour) {
				confidence = confidence + 1;
			} else {
				confidence = 1;
			}

			if (confidence >= beta) {
				goto Decided;
			} else {
				if (!above_alpha) {
					confidence = 0;
				}
				goto InitiateQuery;
			}
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
