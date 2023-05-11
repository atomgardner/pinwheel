// We bind a consensus mechanisms to Node at the module level; this makes the
// test cases generic. The p toolchain expects the bound machine to exist;
// please it with this dummy.
machine Node { start state Init {} }

fun setupNodes(source: machine, n: int): set[machine] {
	var nodes: set[machine];
	var node: machine;
	var i: int;

	while (i < n) {
		nodes += (new Node());
		i = i + 1;
	}

	i = 0;
	foreach (node in nodes) {
		send node, Setup, (source = source, id = i, peers = nodes);
		i = i + 1;
	}

        i = 0;
        while (i < n) {
                receive {
                case Ready: { i = i + 1; }
                }
        }

	return nodes;
}

fun setupClients(src: machine, n: int, peers: set[machine]) {
	var i: int;
	while (i < n) {
		send (new Client()), Setup, (source = src, id = i, peers = peers);
		i = i + 1;
	}
}
