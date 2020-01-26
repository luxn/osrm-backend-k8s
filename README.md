# osrm-backend for Kubernetes
Open Source Routing Machine (OSRM) [osrm-backend](https://github.com/Project-OSRM/osrm-backend) for Kubernetes on AWS EKS. Forked on peter-evans/osrm-backend-k8s which used GKE.

This Docker image and sample Kubernetes configuration files are one solution to persisting [osrm-backend](https://github.com/Project-OSRM/osrm-backend) data and providing immutable deployments.

If you are looking for a more general purpose docker image, see [osrm-backend-docker](https://github.com/peter-evans/osrm-backend-docker).

## Supported tags and respective `Dockerfile` links

- [`1.21.1`, `1.21`, `latest`  (*1.21/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master)
- [`1.20.0`, `1.20` (*1.20/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/archive/1.20)
- [`1.19.0`, `1.19` (*1.19/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/archive/1.19)
- [`1.18.0`, `1.18` (*1.18/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/archive/1.18)
- [`1.17.1`, `1.17` (*1.17/Dockerfile*)](https://github.com/peter-evans/osrm-backend-k8s/tree/master/archive/1.17)

For earlier versions see [releases](https://github.com/peter-evans/osrm-backend-k8s/releases) and the available [tags on Docker Hub](https://hub.docker.com/r/peterevans/osrm-backend-k8s/tags/).

## Usage
The Docker image can be run standalone without Kubernetes:

```bash
docker run -d -p 5000:5000 \
-e OSRM_PBF_URL='http://download.geofabrik.de/asia/maldives-latest.osm.pbf' \
--name osrm-backend peterevans/osrm-backend-k8s:latest
```
Tail the logs to verify the graph has been built and osrm-backend is serving requests:
```
docker logs -f <CONTAINER ID>
```
Then point your web browser to [http://localhost:5000/](http://localhost:5000/)

## Kubernetes Deployment
The [osrm-backend](https://github.com/Project-OSRM/osrm-backend) builds a data graph from a PBF file. This process can take over an hour for a single country.
If a pod in a deployment fails, waiting over an hour for a new pod to start could lead to loss of service.

The sample Kubernetes files provide a means of persisting a data graph in storage that is used by all pods in the deployment. 
Each pod having their own copy of the graph is desirable in order to have no single point of failure.

#### Explanation
Initial deployment flow:

1. Create AWS IAM credentials that that has read/write permissions to S3 (using awscli).
2. Deploy the canary deployment.
3. Wait for the graph to be built and uploaded to S3.
4. Delete the canary deployment.
5. Deploy the stable track deployment.

To update the live deployment with a new graph:

1. Deploy the canary deployment alongside the stable track deployment.
2. Wait for the graph to be built and uploaded to S3.
3. Delete the canary deployment.
4. Perform a rolling update on the stable track deployment to create pods using the new graph.


#### Deployment configuration
Before deploying, edit the `env` section of both the canary deployment and stable track deployment.

- `OSRM_MODE` - `CREATE` from PBF data, or `RESTORE` from S3.
- `OSRM_PBF_URL` - URL to PBF data file. (Optional when `OSRM_MODE=RESTORE`)
- `OSRM_GRAPH_PROFILE` - Graph profile; `car`,`bicycle` or `foot`. (Optional when `OSRM_MODE=RESTORE`)
- `OSRM_DATA_LABEL` - A meaningful and **unique** label for the data. e.g. maldives-car-20161209
- `OSRM_AWS_ACCESS_KEY_ID` - AWS access key id
- `OSRM_AWS_SECRET_ACCESS_KEY` - AWS secret access key
- `OSRM_AWS_DEFAULT_REGION` - AWS region e.g. eu-central-1
- `OSRM_AWS_S3_BUCKET` - S3 bucket.

## License

MIT License - see the [LICENSE](LICENSE) file for details