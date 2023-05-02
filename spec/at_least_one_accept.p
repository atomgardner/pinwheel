spec AtLeastOneAccept observes Accept {
	start hot state Pending {
		on Accept do (r: TxResponse) {
			assert r.colour != None,
				"slusher accepted an undecided value";
			goto Accepted;
		}
	}
	state Accepted {
                on Accept do {
                        goto Accepted;
                }
        }
}
