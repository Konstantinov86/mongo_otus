[mongo_cfg_instances]
%{ for ip in mongo_cfg_instances ~}
${ip}
%{ endfor ~}

[mongo_shard_instances]
%{ for ip in mongo_shard_instances ~}
${ip}
%{ endfor ~}

[mongos_instances]
%{ for ip in mongos_instances ~}
${ip}
%{ endfor ~}
