# Lab 

The lab is setup as described in the diagram:

    172.16.124.0/24
    +-----------------------------------------------------+
        .50 |     .51 |        .52 |        .53 |
            |         |            |            |
            |         |            |            |
        +------+  +-------+  +----------+  +--------+
        |      |  |       |  |          |  |        |
        | dc01 |  | web01 |  | client01 |  | adfs01 |
        |      |  |       |  |          |  |        |
        +------+  +-------+  +----------+  +--------+

* `dc01`: setup a _domain controller_ for domain `lab.local`, all other
servers are joined to the domain.
* `web01`: setup an _IIS_ server for FQDN `www.lab.local` with windows 
integrated authentication activated.
* `client01`: another server that acts as a client. Chrome is installed and
setup to work do allow for WIA authentication with *.lab.local.
* `adfs01`: [EXPERIMENTAL] setup an ADFS server for experimentation with 
_external_ domain `extlab.local`.

# Run

Before you run `vagrant up` edit the `Vagrantfile` to adapt those variables:

    $NET_PREFIX       = "172.16.124"
    $BRIDGE_IF        = "vmnet1"
    $DOWNLOADS_DIR    = "/Volumes/EXT/Downloads"

The network prefix should be adapted to whatever network you bridge too (make
sure the IPs 50 to 53 are free or change them as well in the file). All VMs
are bridge to the same interface. In my case the VMWare network that hosts my
virtual Netscaler instance. The download dir should contain `googlechromestandaloneenterprise.msi`
which can be downloaded from here: https://www.google.com/work/chrome/chrome-browser/

# Tests

To test that IIS and WIA authentication are properly setup go to the `client01` 
VM, open a PowerShell console and execute the following command:

    C:\Sysinternals\psexec -accepteula -u LAB\Alice -p Passw0rd "C:\Program Files\Internet Explorer\iexplore" http://www.lab.local/

If everything went according to plan you should see `Hello World!` in the browser.

# Annex

I also use the lab for NetScaler configuration testing. In which case I would launch NetScaler in VMWare Fusion (hence the bridge with `vmnet1`):


                                +------+
                                |      |
                                | ns01 |
                                |      |
                                +--+---+
                                    |
                           NSIP .10 | .11 SNIP
    172.16.124.0/24                 | .12 VIP
    +-------+---------+------------++-----------+---------+
        .50 |     .51 |        .52 |        .53 |
            |         |            |            |
            |         |            |            |
        +---+--+  +---+---+  +-----+----+  +----+---+
        |      |  |       |  |          |  |        |
        | dc01 |  | web01 |  | client01 |  | adfs01 |
        |      |  |       |  |          |  |        |
        +------+  +-------+  +----------+  +--------+