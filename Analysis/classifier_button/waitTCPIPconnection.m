function res = waitTCPIPconnection()
% res = waitTCPIPconnection()
%
% Establishes TCP/IP socket connection with a client application and
% return communication channels for further processing.
%
% Author : Christoforos Christoforou
% Date :  July 25 2008
%
% Revision: 


import java.net.Socket;
import java.net.ServerSocket;
import java.io.*;

global TCPIPstruct;

res = [];
port = 4444;   % The port at which  server is listening for connections



%
% Create a server Socket
%

serverSocket = ServerSocket(port);
fprintf('Waiting for TCP/IP connection by a client application....To exit press q \n');
serverSocket.setSoTimeout(10000);
try
  clientSocket = serverSocket.accept();
catch
  close(serverSocket)
  res.nonefield = 0;
  return
end;

% Open input and output streams

osw = OutputStreamWriter(clientSocket.getOutputStream());
isr = InputStreamReader(clientSocket.getInputStream());
os = BufferedWriter(osw);
is = BufferedReader(isr);

fprintf('Connection Established!!!!\n');


%
% Define a structure of network connections to be passed as argument
%

TCPIPstruct.serverSocket = serverSocket;
TCPIPstruct.clientSocket = clientSocket;
TCPIPstruct.osw = osw;
TCPIPstruct.isr = isr;
TCPIPstruct.os = os;
TCPIPstruct.is = is;


res = TCPIPstruct;
