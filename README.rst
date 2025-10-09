===
PCC
===

**P**\ erformance-oriented **C**\ ongestion **C**\ ontrol.

The version adjust some parameters to adapt to bad network and uses the utility function from Proteus-P.

Origin source is 
`here <https://github.com/PCCproject/PCC-Kernel/tree/vivace>`_.

=========
Using PCC
=========

One click script to install the kernel module:

.. code:: bash

  curl -fsSL https://raw.githubusercontent.com/flben233/PCC-Plus/refs/heads/vivace/install.sh | bash

To uninstall:

.. code:: bash

  rm /etc/sysctl.d/99-tcp_pcc.conf
  reboot
  rmmod tcp_pcc
