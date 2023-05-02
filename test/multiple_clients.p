// A virtuous multi-client setup should lead to consensus.
machine TestWithVirtuousClients {
	start state Init {
		entry {
			var numClients: int;
			var numNodes: int;
			var nodes: set[Slusher];

			// loop variables
			var c: Client;
			var node: Slusher;
			var i: int;

			numNodes = 5;
			numClients = 2;

			while (i < numNodes) {
				nodes += (new Slusher());
				i = i + 1;
			}

			// use a fully connected network (for simplicity)
			i = 0;
			foreach (node in nodes) {
				send node, Setup, (id = i, peers = nodes);
				i = i + 1;
			}

			i = 0;
			while (i < numClients) {
				c = new Client();
				send c, Setup, (id = i, peers = nodes);
				i = i + 1;
			}
		}
	}
}
