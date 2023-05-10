// A single client should lead to eventual consensus.
machine TestWithSingleClient {
	start state Init {
		entry {
			setupClients(1, setupNodes(5));
		}
	}
}
