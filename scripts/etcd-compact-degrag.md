# Etcd Database Space Exceeded

When etcd space usage has reached quota, etcd raises a cluster-wide alarm and puts
the cluster into a maintenance mode which only accepts reads and deletes.
Only after freeing enough space in the keyspace and defragmenting the backend database,
along with clearing the space quota alarm can the cluster resume normal operation.

Follow these steps to remediate.

## Requirements

Install the etcd client on the Ubuntu node.

```sh
$ apt install etcd-client
```

## Symptoms

When etcd backend database reaches capacity, only reads and deletes are allowed.
Kubernetes clusters will experience strife. Attempts to create new resouces will fail.

Typical failure message.

```sh
error: failed to patch: etcdserver: mvcc: database space exceeded
```

## Remediation

Follow these steps to deal with the etcd database space issues and recover the Kubernetes cluster.

Perform these steps on all the server instances where the etcd cluster is running.

Use the v3 api.

```sh
export ETCDCTL_API=3
```

### Get the connect values from this command

```sh
systemctl status | grep etcd
```

### Get endpoints status

Get current endpoint status. Obtain the endpoints value from the systemctl status above.

```sh
etcdctl --endpoints=https://10.91.130.2:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key endpoint status --write-out=table
```

Output

```sh
+--------------------------+------------------+---------+---------+-----------+-----------+------------+
|         ENDPOINT         |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
+--------------------------+------------------+---------+---------+-----------+-----------+------------+
| https://10.91.130.2:2379 | ad97d371d0097c1c |  3.5.12 |  2.1 GB |      true |         2 |   39154906 |
+--------------------------+------------------+---------+---------+-----------+-----------+------------+

```

### Get and set revision

Get the etcd revision value.

```sh
REVISION=$(etcdctl --endpoints=https://10.91.130.2:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key endpoint status --write-out="json" | egrep -o '"revision":[0-9]*' | egrep -o '[0-9].*')
echo $REVISION
```

### Compact

```sh
etcdctl --endpoints=https://10.91.130.2:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key compact $REVISION
```

Output

```sh
compacted revision 32973171
```

### Defrag

Defragment the database after compaction.

```sh
etcdctl --endpoints=https://10.91.130.2:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key defrag
```

Output

```sh
Finished defragmenting etcd member[https://10.91.130.2:2379]
```

### List alarms

List the etcd cluster alarms.

```sh
etcdctl --endpoints=https://10.91.130.2:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key alarm list
```

Output

```sh
memberID:12508698975819889692 alarm:NOSPACE
```

### Disarm alarms

Disarm the activated alarms.

```sh
etcdctl --endpoints=https://10.91.130.2:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key alarm disarm
```

### Check endpoint status

Confirm the database status.

```sh
etcdctl --endpoints=https://10.91.130.2:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key endpoint status --write-out=table
```

Output

```sh
+--------------------------+------------------+---------+---------+-----------+-----------+------------+
|         ENDPOINT         |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
+--------------------------+------------------+---------+---------+-----------+-----------+------------+
| https://10.91.130.2:2379 | ad97d371d0097c1c |  3.5.12 |  861 MB |      true |         2 |   39164544 |
+--------------------------+------------------+---------+---------+-----------+-----------+------------
```

## References

https://etcd.io/docs/v3.3/op-guide/maintenance/