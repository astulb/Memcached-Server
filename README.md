## Memcached Server

### RETRIEVAL COMMANDS

   * **get:** get key*
   * **gets:** gets key*

key* means one or more key strings separated by a white-space.

### STORAGE COMMANDS

Storage commands have two parts, starting with the following:

   * **set:** set key flags ttl bytes			
   * **add:** add key flags ttl bytes			
   * **replace:** replace key flags ttl bytes       			
   * **append:** append key flags ttl bytes  			
   * **prepend:** prepend key flags ttl bytes			
   * **cas:** cas key flags ttl bytes cas_unique

**key:** It's the key under which the client asks to store the data.

**flags:** Use this as a bit field to store data-specific information.

**ttl:** It's the expiration time. If it's 0, the item never expires.

**bytes:** It's the number of bytes in the data block to follow, not including the delimiting "\r\n".

**cas_unique:** It's a unique 64-bit value of an existing entry.
Clients should use the value returned from the "gets" command when issuing "cas" updates.

After this line, a data block is expected:

   * **data block:** data

**data:** is a chunk of data of length "bytes" from the previous line.

### How to configure the server:

To configure the ip and port the server will be working on, modify the Config.rb file.
    
By default the port is set to "1234" and the server ip to "localhost".

### How to run the server:

In your terminal run "ruby Run_Server.rb" while at the project directory

### How to connect to the server:

In your terminal, use telnet to connect to the server with the next command: telnet <IP> <PORT>

If the Config.rb file was kept as default then the following command will connect you to the server
    
```bash
telnet localhost 1234
```

### How to run the tests:

First install the rspec ruby gem with the following command in your terminal:

```
gem install rspec
```

After the installation, run the tests with the following command while at the project directory:

```
rspec spec Memcached_spec.rb
```


