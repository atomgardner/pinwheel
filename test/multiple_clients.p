// A virtuous multi-client setup should lead to consensus.
machine TestWithVirtuousClients {
	start state Init {
		entry {
			setupClients(this, 2, setupNodes(this, 5));
		}
	}
}
