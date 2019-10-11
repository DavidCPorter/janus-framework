package com.dporte7.solrclientserver;
import org.apache.solr.client.solrj.impl.CloudSolrClient;
import java.net.ServerSocket;
import java.net.Socket;
import java.io.IOException;
import java.util.Arrays;

/**
 *
 * @author dporter
 */
public class MultiThreadedServer implements Runnable{
    private int          serverPort;
    private ServerSocket pyServer = null;
    private boolean      isStopped    = false;
    private Thread       runningThread= null;
    private static String defaultCollection = "reviews";

    public MultiThreadedServer(int port){
        this.serverPort = port;
    }

    public void run(){
        // creates pyServer socket


        openServerSocket();

        // listens for connections then hands to another thread - WorkerRunnable
        // so each request from the pyServer (traffic_gen.py) is passed to a new thread.
        while(!isStopped()){
            //creates new socket variable and assigns it to a new connection.

            Socket pySocket = new Socket();

            CloudSolrClient instance;
            try {
                System.out.println("listening for new connections");
                pySocket = this.pyServer.accept();
                System.out.println("accepted connection."+ String.valueOf(serverPort));
                CloudSolrClient.Builder builder = new CloudSolrClient.Builder();
                builder.withZkHost(Arrays.asList("10.10.1.1:2181","10.10.1.2:2181","10.10.1.3:2181"));
                instance = builder.build();
                final int zkClientTimeout = 9999;
                final int zkConnectTimeout = 9999;
                instance.setDefaultCollection(defaultCollection);
                instance.setZkClientTimeout(zkClientTimeout);
                instance.setZkConnectTimeout(zkConnectTimeout);
                instance.connect();
            } catch (IOException e) {
                if(isStopped()) {
                    System.out.println("Server Stopped.") ;
                    return;
                }
                throw new RuntimeException(
                        "Error accepting client connection", e);
            }
            // passes socket object and a solrj connection to a new thread to handle request
            new Thread(
                    new WorkerRunnable(
                            this.isStopped, pySocket, instance , "Multithreaded Server")
            ).start();

        }
        System.out.println("Server Stopped.") ;
    }

    private synchronized boolean isStopped() {
        return this.isStopped;
    }

    public synchronized void stop(){
        this.isStopped = true;
        try {
            this.pyServer.close();
        } catch (IOException e) {
            throw new RuntimeException("Error closing server", e);
        }
    }

    private void openServerSocket() {
        try {
            //serversocket just creates a server
            this.pyServer = new ServerSocket(this.serverPort);
        } catch (IOException e) {
            throw new RuntimeException("Cannot open serverPort", e);
        }
    }

}
