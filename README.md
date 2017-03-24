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

# Annex 1: NetScaler Setup

## Lab setup for NetScaler testing

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

To test NetScaler authentication: ensure the lab was created with variable environment `WITH_NETSCALER` set to `true` or execute provisioning files `03_populate_AD2.ps1` in `DC01` and `05_populate_adfs.ps1` in `ADFS01`.

## NetScaler configuration

After provisioning a NetScaler instance place a license file in the `licenses` directory (by default the script uses `ns01.lic`)

To connect to the NetScaler instance:

    ./NSConfig.ps1 -Connect

This command will completely reset your NetScaler instance to prepare it for a new configuration:

    ./NSConfig.ps1 -Reset
    ./NSConfig.ps1 -Bootstrap

Finally deploying the configuration is done with:

    ./NSConfig.ps1 -Verbose

If you do not require a full instance reset (with certificate file and license cleanup), you can use:

    Clear-NSConfig -Level Full -Force; ./NSConfig.ps1 -Verbose

Those two commands allow for a faster feedback loop when working on the NetScaler configuration.

## NetScaler configuration testing

To test the NetScaler configuration, just enter [https://www.extlab.local][https://www.extlab.local] into a browser in the `client01` host.

# Annex 2: Certificate generation

We use auto-signed SSL certificates in the lab. They are stored in the `certs` directory and where generated with the code present in `Contrib\New-TestCertificates.ps1`.

The _ADFS Token Signing_ certificate is generated during ADFS installation and stored in the `tmp` directory. The certificate is then reused by the NetScaler configuration script. This directory's content is not committed to source control because each ADFS installation will be different.

# Annex 3: Generating the lab's Windows base box

Vagrant uses _base boxes_ to build virtual machines. To build the _base box_ for this lab you will need to install [Packer][https://www.packer.io/] and :

    git clone https://github.com/dbroeglin/packer-templates.git
    cd packer-templates
    packer build -force -only virtualbox-iso vbox-2012r2-wmf5.json

Once the _base box_ is built, import it with the following command:

    vagrant box add --name windows2012r2min-wmf5-virtualbox windows2012r2min-wmf5-virtualbox.box

You should be ready to go. 

Before running packer, you might want to customize the build to your preferences. For instance, the keyboard layout can be changed here: https://github.com/dbroeglin/packer-templates/blob/master/scripts/postunattend.xml#L14