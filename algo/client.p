machine Client {
	var peers: set[machine];

	start state Init {
		entry {
			receive {
				case Setup: (c: Config) {
					peers = c.peers;
				}
			}
			goto PickAColour;
		}
	}

	state PickAColour {
		entry {
			if ($) {
				send choose(peers), Transaction,
					(source = this, colour = Red);
			} else {
				send choose(peers), Transaction,
					(source = this, colour = Green);
			}
			goto WaitForAccept;
		}
	}

	state WaitForAccept {
		on Accept do (r: TxResponse) {
			print format("accepted with {0}", r);
		}
	}
}
