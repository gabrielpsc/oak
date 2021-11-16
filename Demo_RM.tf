# VCN comes with default route table, security list and DHCP options

variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}

provider "oci" {
  tenancy_ocid     = "${var.tenancy_ocid}"
  region           = "${var.region}"
}

resource "oci_core_vcn" "vcn1" {
  cidr_block     = "172.20.0.0/16"
  dns_label      = "RM Webinar"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "RM Webinar"
}

// A regional subnet will not specify an Availability Domain
resource "oci_core_subnet" "Subnet_Demo" {
  cidr_block        = "172.20.0.0/24"
  display_name      = "Subnet_Demo_RM"
  dns_label         = "SubnetDemo"
  compartment_id    = "${var.compartment_ocid}"
  vcn_id            = "${oci_core_vcn.vcn1.id}"
  security_list_ids = ["${oci_core_vcn.vcn1.default_security_list_id}"]
  route_table_id    = "${oci_core_vcn.vcn1.default_route_table_id}"
  dhcp_options_id   = "${oci_core_vcn.vcn1.default_dhcp_options_id}"
}


resource "oci_core_internet_gateway" "test_internet_gateway" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "testInternetGateway"
  vcn_id         = "${oci_core_vcn.vcn1.id}"
}

resource "oci_core_default_route_table" "default_route_table" {
  manage_default_resource_id = "${oci_core_vcn.vcn1.default_route_table_id}"
  display_name               = "defaultRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = "${oci_core_internet_gateway.test_internet_gateway.id}"
  }
}

resource "oci_core_route_table" "route_table1" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_vcn.vcn1.id}"
  display_name   = "routeTable1"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = "${oci_core_internet_gateway.test_internet_gateway.id}"
  }
}

resource "oci_core_default_dhcp_options" "default_dhcp_options" {
  manage_default_resource_id = "${oci_core_vcn.vcn1.default_dhcp_options_id}"
  display_name               = "defaultDhcpOptions"

  // required
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  // optional
  options {
    type                = "SearchDomain"
    search_domain_names = ["abc.com"]
  }
}

resource "oci_core_default_security_list" "default_security_list" {
  manage_default_resource_id = "${oci_core_vcn.vcn1.default_security_list_id}"
  display_name               = "defaultSecurityList"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }

  // allow outbound udp traffic on a port range
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "17"        // udp
    stateless   = true

    udp_options {
      min = 319
      max = 320
    }
  }

  // allow inbound ssh traffic
  ingress_security_rules {
    protocol  = "6"         // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  // allow inbound icmp traffic of a specific type
  ingress_security_rules {
    protocol  = 1
    source    = "0.0.0.0/0"
    stateless = true

    icmp_options {
      type = 3
      code = 4
    }
  }
}

resource "oci_database_autonomous_database" "rm_autonomous_database" {
    #Required
    admin_password = "Q1w2e3r4t5Y6*"
    compartment_id = "${var.compartment_ocid}"
    cpu_core_count = "1"
    data_storage_size_in_tbs = "1"
    db_name = "orcl"
    display_name = "Demo Resource Manager"
    db_workload = "DW"
}
