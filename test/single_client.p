// A single client should lead to eventual consensus.
machine TestWithSingleClient {
	start state Init {
		entry {
			setupClients(this, 1, setupNodes(this, 5));
		}
	}
}
