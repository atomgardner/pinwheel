spec Consensus observes Accept, Transaction {
	var pending: int;
	var c: Colour;

	start state Balanced {
		on Transaction do {
			pending = pending + 1;
			goto Unbalanced;
		}

		// This assumes messages wont be rebroadcast.
		on Accept do {
			assert true == false,
                               "received accept before transaction";
		}
	}

	hot state Unbalanced {
		on Transaction do {
			pending = pending + 1;
		}

		on Accept do (r: TxResponse) {
			assert r.colour != None,
				"slusher accepted an undecided value";
			if (c == None) {
				c = r.colour;
			}
			assert r.colour == c,
			       "machines accepted different colours";
			pending = pending - 1;
			if (pending == 0) {
				goto Balanced;
			}
			goto Unbalanced;
		}
	}
}
