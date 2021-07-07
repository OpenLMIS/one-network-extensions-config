# OpenLMIS Extensions Config
This is a Docker image containing extensions of OpenLMIS services for One Network integration.


## Quick start
1. Fork/clone this repository from GitHub.
 ```shell
 git clone https://github.com/OpenLMIS/one-network-extensions-config.git
 ```
2. Add an environment file called `.env` to the root folder of the project, with the required 
project settings and credentials. For a starter environment file, you can use [this 
one](https://raw.githubusercontent.com/OpenLMIS/openlmis-ref-distro/master/settings-sample.env). eg:
 ```shell
 curl -o .env -L https://raw.githubusercontent.com/OpenLMIS/openlmis-ref-distro/master/settings-sample.env
 ```
3. Develop w/ Docker by running `docker-compose run --service-ports extensions-config`.

4. Start up the application.
 ```shell
 docker-compose -f ref-distro-example-docker-compose.yml up
 ```

## <a name="buildimage">Build Deployment Image</a>
The specialized docker-compose.builder.yml is geared toward CI and build 
servers for automated building, testing and docker image generation of 
the service.

Before building the deployment image, make sure you have a `.env` file as outlined in the Quick
Start instructions.

```shell
> docker-compose -f docker-compose.builder.yml run builder
> docker-compose -f docker-compose.builder.yml build image
```

## Integration with openlmis-ref-distro
1. Fork/clone `openlmis-ref-distro` repository from GitHub.
 ```shell
 git clone https://github.com/OpenLMIS/openlmis-ref-distro.git
 ```
2. Start up openlmis-ref-distro.
 ```shell
    docker-compose -f docker-compose.one-network-referencedata-extension.yml up
 ```
 
## <a name="extensionpoints">Adding extension points</a>
1. Add extension to the "dependencies" configuration in build.gradle:
```
    extension "org.openlmis:one-network-referencedata-extension:0.0.1-SNAPSHOT"
```
2. Modify extensions.properties with name of the extended component.
```
    OrderableCreatePostProcessor=OrderableCreateEvent
	OrderableUpdatePostProcessor=OrderableUpdateEvent
```


## <a name="configuringrefdistro">Configuring openlmis-ref-distro</a>
The Reference Distribution is configured to use extension modules by defining a named volume that is common to the service and partner image. 
```
volumes:
  example-extensions:
    external: false
```
The shared volume contains extension jars and extension point configuration. The role of this image is to copy them at start-up, so they may be read by the service.

An example configuration can be found in openlmis-ref-distro as `docker-compose.one-network-referencedata-extension.yml`.

## Implementing new Extension Point in OpenLMIS
#### Prepare core service to enable extensions
1. Add [ExtensionManager](https://github.com/OpenLMIS/openlmis-stockmanagement/blob/master/src/main/java/org/openlmis/stockmanagement/extension/ExtensionManager.java) 
and [ExtensionException](https://github.com/OpenLMIS/openlmis-stockmanagement/blob/master/src/main/java/org/openlmis/stockmanagement/extension/ExtensionException.java) 
to src/extension in the repository where extension point should be included [(See commit here)](https://github.com/OpenLMIS/openlmis-stockmanagement/commit/610845042a33ae6391e79b8492ab4be9ed2f4478).
2. Add extension point interface in src/extension/point, for example: [AdjustmentReasonValidator](https://github.com/OpenLMIS/openlmis-stockmanagement/blob/master/src/main/java/org/openlmis/stockmanagement/extension/point/AdjustmentReasonValidator.java).
3. Add final ExtensionPointId class with the extension point ids defined like [here](https://github.com/OpenLMIS/openlmis-stockmanagement/blob/master/src/main/java/org/openlmis/stockmanagement/extension/point/ExtensionPointId.java#L20).
4. Add Default class which implements the extension point interface. See an [example](https://github.com/OpenLMIS/openlmis-stockmanagement/blob/master/src/main/java/org/openlmis/stockmanagement/validators/DefaultAdjustmentReasonValidator.java).
Default class needs to have Component annotation with the value of its id:
```
@Component(value = "DefaultAdjustmentReasonValidator")
```
5. Update the usage of the extension point. Now it should use ExtensionManager to find proper implementation. See example [here](https://github.com/OpenLMIS/openlmis-stockmanagement/blob/c6b882f37e00f38fc6e895dc644b34108dfa3efd/src/main/java/org/openlmis/stockmanagement/service/StockEventValidationsService.java#L100). 
6. Add runtime dependency to build.gradle file in the repository like [here](https://github.com/OpenLMIS/openlmis-stockmanagement/blob/8e9ccf50a7b9e141bb7d4fae225fead9514b1b8f/build.gradle#L73).
7. In build.gradle add tasks that sign archives and publishes repository itself to Maven (check details in this [ticket](https://openlmis.atlassian.net/browse/OLMIS-6954)).
8. Run the CI build job to publish the repository to Maven.
#### Extension point implementation and usage
1. Create a new extension module, which contains code that overrides extension point, for example: [openlmis-stockmanagement-validator-extension](https://github.com/OpenLMIS/openlmis-stockmanagement-validator-extension).
2. Annotate your implementation of the extension point with @Component annotation with the value of its id like [here](https://github.com/OpenLMIS/openlmis-stockmanagement-validator-extension/blob/master/src/main/java/org/openlmis/stockmanagement/validators/NoneValidator.java#L27).
3. Create an appropriate CI job ([example](http://build.openlmis.org/job/OpenLMIS-stockmanagement-validator-extension/)). Build the job to publish the repository to Maven.
4. Create a new extensions module which collects extension points for all services. The [openlmis-example-extensions](https://github.com/OpenLMIS/openlmis-example-extensions) is an example of such a module.
5. Modify [extensions.properties](https://github.com/OpenLMIS/openlmis-example-extensions/blob/master/extensions.properties#L2) with the name of the extended component 
6. Add the extension to the "dependencies" configuration in [build.gradle](https://github.com/OpenLMIS/openlmis-example-extensions/blob/master/build.gradle#L14).
7. Create a dedicated docker-compose.yml file with the example-extensions service. See the example: [docker-compose.openlmis-stockmanagement-validator-extension.yml](https://github.com/OpenLMIS/openlmis-ref-distro/blob/master/docker-compose.openlmis-stockmanagement-validator-extension.yml#L90).
7. Add the extensions module as [volume](https://github.com/OpenLMIS/openlmis-ref-distro/blob/master/docker-compose.openlmis-stockmanagement-validator-extension.yml#L101) to the extended service in the docker-compose.yml file.
