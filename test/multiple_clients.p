// A virtuous multi-client setup should lead to consensus.
machine TestWithVirtuousClients {
	start state Init {
		entry {
			setupClients(2, setupNodes(5));
		}
	}
}

fun setupNodes(n: int): set[Slusher] {
	var nodes: set[Slusher];
	var node: Slusher;
	var i: int;

	while (i < n) {
		nodes += (new Slusher());
		i = i + 1;
	}

	i = 0;
	foreach (node in nodes) {
		send node, Setup, (id = i, peers = nodes);
		i = i + 1;
	}

	// TODO: wait for nodes to be ready?

	return nodes;
}

fun setupClients(n: int, peers: set[Slusher]) {
	var i: int;
	while (i < n) {
		send (new Client()), Setup, (id = i, peers = peers);
		i = i + 1;
	}
}
