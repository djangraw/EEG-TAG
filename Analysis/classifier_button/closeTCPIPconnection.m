function closeTCPIPconnection()



import java.net.Socket;
import java.net.ServerSocket;
import java.io.*;

global TCPIPstruct;

close(TCPIPstruct.serverSocket);
close(TCPIPstruct.clientSocket);
close(TCPIPstruct.osw);
close(TCPIPstruct.isr);
close(TCPIPstruct.os);
close(TCPIPstruct.is);
