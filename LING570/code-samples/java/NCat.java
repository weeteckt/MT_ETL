import java.io.*;


class NCat {
public static void main (String[] args) throws IOException {
	String line;
    BufferedReader stdin = new BufferedReader
      (new InputStreamReader(System.in));

	// If there are no command line arguments, n=-1 will cause the loop to
	// continue until STDIN is exhausted.
	int n = args.length == 0 ? -1 : Integer.parseInt(args[0]);

	while (true) {
		if (n-- == 0)
			break;
		line = stdin.readLine();
		if (line == null)
			break;
		System.out.println(line);
	}
  }
}

