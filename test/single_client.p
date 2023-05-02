// A single client should lead to eventual consensus.
machine TestWithSingleClient {
	start state Init {
		entry {
			var nodes: set[Slusher];
			var numNodes: int;
			// loop vars
			var i: int;
			var node: Slusher;

			numNodes = 5;

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

			send (new Client()), Setup, (id = 0, peers = nodes);
		}
	}
}
