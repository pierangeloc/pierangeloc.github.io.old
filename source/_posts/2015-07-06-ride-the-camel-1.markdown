---
layout: post
title: "ride-the-camel-1"
date: 2015-07-06 21:11:55 +0200
comments: true
categories: 
---
Any application that does a bit more than printing `hello world` must relate with other systems. These systems might be File system, databases, webservices, message queues, logging systems, or systems using a particular communication protocol. The variety of combinations this allows is enormous, and tackling each of these in a hand made, custom way might easily become a integration nightmare. _Enterprise Integration Patterns_ (EAI) establish a standard way to describe and identify the different approaches that one can follow to deal with an integration problem (see [http://www.enterpriseintegrationpatterns.com](http://www.enterpriseintegrationpatterns.com)). They establish a common vocabulary that can be used unambiguously when talking about integration problems. If we consider that integration problems are ubuquitous in application development, we realize easily how convenient it might be to have solid foundations on this subject.

Apache Camel is a framework that implements EAIs through a very expressive DSL, so you can translate almost immediately any EAI to a corresponding expression in the DSL. Moreover, Camel provides an extensible set of components that allow you to deal with basically any system that might come at hand. A key feature of Camel is that it deals with a normalized message format, so after the consumption point the message has a standard format, e.g. it can be handled identically either if it comes from consuming from a JMS queue or from a SOAP or REST webservice. 

It is easier to grasp the concepts setting up a simple Camel project and seeing these features at work.

Camel is a Spring-based framework, so to make use of it the easiest way is to include it in your Spring context. We will use Camel 2.15.1 that provides a way to setup a Camel-based application without a line of xml configuration.

####Maven Dependencies
First of all let's include the dependencies in our `pom.xml`:

```XML
    <dependencies>

        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>3.8.1</version>
            <scope>test</scope>
        </dependency>

        <!-- camel -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-core</artifactId>
            <version>${camel.version}</version>
        </dependency>

        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-spring</artifactId>
            <version>${camel.version}</version>
        </dependency>

        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-spring-javaconfig</artifactId>
            <version>${camel.version}</version>
        </dependency>
    </dependencies>

```

`camel-core` provides the essence of the camel infrastructure and basic components, `camel-spring` and `camel-spring-javaconfig` provide the classes and annotations that allow us to configure and run Camel within a Java-configured Spring application.

####Embed Camel in a bootable application
The `org.apache.camel.spring.javaconfig.CamelConfiguration` abstract class can be used as a base Spring configuration class, where we can reference all the beans we might need in the standard Spring way (xml or annotations based). The additional thing that this class does is loading a `CamelContext` and injecting any `RouteBuilder` descendent class that might be available in the Spring context.
To give ourselves some more flexibility we will also make use of a standard xml spring configuration.

The simplest configuration of such an application boils down to:

```Java
/**
 * We extend CamelConfiguration so we can build a Camel Context using purely annotated classes
 *
 */
@Configuration
public class Boot extends CamelConfiguration {

    public static void main( String[] args ) throws Exception {
        Main main = new Main();
        //use any route builder and components declared within this package
        main.setFileApplicationContextUri("classpath:/spring/spring.xml");
        main.setBasedPackages("nl.sytac.edu");
        main.run();
    }

    @Bean
    public RouteBuilder getSimpleRouteBuilder() {
        return new SimpleRouteBuilder();
    }
}
```

###### Integrating Camel in an existing (web) application
If you want to integrate Camel in an existing application, injecting a `CamelContext` in an existing Spring application context is pretty straightforward, see e.g. [https://github.com/pierangeloc/webshop-camel-springmvc](https://github.com/pierangeloc/webshop-camel-springmvc) for an example of how to integrate Camel within an existing web application.

###Simple Example
Now that we outlined the base structure of a Camel-based application, let's try to put this at work and build a simple application. The purpose is just to show how we can have a working application with minimum effort. Let us suppose we have a small ERP application that provides us periodically an updated  stock situation, and we want to provide this information to a couple of other applications, e.g. an e-commerce and an analytics application. We want to expose a simple REST service, with one URL and supporting only POST method. The aim is to persist the body of our POST call in two files, in two configured locations. A file will be created for every request.

####Setup Rest Endpoint
The most convenient way to expose or consume a REST or SOAP webservice in Camel is to use the CXF component. With CXF we can use `JAX-RS` and `JAX-WS` annotations to configure the service classes.

The first thing we must do is to setup the serving class that describes the resource we want to expose:

```Java
package io.sytac.edu.rest;

import javax.ws.rs.Consumes;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Response;

/**
 * Service class for our REST endpoint
 */

@Path("/inventory/status")
public class InventoryResource {

    @POST
    @Consumes("application/json")
    @Produces("application/json")
    public Response updateStatus(String status) {
        return null;
    }
}
```

We provided a trivial implementation of the method, as the real implementation of the logic will be delegated to the route we are about to create. The Jax-RS annotations allow us to specify in a transparent way the supported content types, having the implementation to take care of enforcing them.
To make thi endpoint available to our route, the most flexible way is to create a CXF bean that delegates to it, and to set it in our Spring context:

```
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:cxf="http://camel.apache.org/schema/cxf"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
              http://camel.apache.org/schema/cxf http://camel.apache.org/schema/cxf/camel-cxf.xsd
              http://camel.apache.org/schema/spring http://camel.apache.org/schema/spring/camel-spring.xsd">

        <cxf:rsServer id="restInventory" address="http://localhost:8000/services"
                serviceClass="io.sytac.edu.rest.InventoryResource" loggingFeatureEnabled="true"/>

</beans>
```

Here we created an `cxf:rsServer` bean as we want it to serve requests, and specified the hostname, port, base url in a very straightforward way. The serviceClass points to the class we defined above. Again, the implementation of this class is just ignored as the real processing of the request is specified in the route, which we are about to describe. 





















####Camel foundations
Camel is built around some key concepts that we will try to explain in this section: `CamelContext`, `RouteBuilder`, `Endpoint` `Exchange`, `Message`, `ProducerTemplate`

###`CamelContext`
The foundation on top of which all the Camel machinery runs is the `CamelContext`, which is in control of the lifecycle of the routes and messages running on it. A `CamelContext` can be started/suspended/resumed/stopped, and it provides a number of configuration tweaks, e.g. to handle the underlying `ExecutorService`.
A `CamelContext` can manage many _routes_, which represent processing paths for _messages_.

###`RouteBuilder`
A `Route` is a description of the processing steps a message can encounter. A route starts from a _consumer_ endpoint that consumes messages and process them, and can end to a _producer_ endpoint if the messages must result in an outcome of some type (e.g. a call to a webservice, or a message on a JMS queue). The standard way to create a `Route` in Camel is to inject a `RouteBuilder` in the `CamelContext` and override its `define()` method.
The `RouteBuilder` class provides the Camel DSL which makes the implementation of EIP straightforward. We will see later a few examples of routes.

###`Endpoint`
A `Route` could not process messages without a source of these messages, which is a _consumer_ endpoint, and without a destination to which messages can be delivered after being processed, a _producer_ endpoint. The concept of _endpoint_ is itself an EIP [http://www.enterpriseintegrationpatterns.com/MessageEndpoint.html](http://www.enterpriseintegrationpatterns.com/MessageEndpoint.html) and it is a cornerstone of the Camel solution to the integration problem: regardless of the nature of the producer or consumer endpoint, the intermediate steps deal with a message that have a standard structure and is in general agnostic about the nature of the source or destination of the message. The processing steps along the route deal with the same type of message, whether it came to the route through a webservice exposed by the route, or because it has been delivered as a file on a directory the route is listening to. The webservice, or the file listening service, are different implementations of a _consuming_ endpoint.

###`Exchange`
Endpoints can produce or consume `Exchange`s. An `Exchange` is structured in an IN and an OUT message. When dealing with a _consumer endpoint_, we can see it as a source of `Exchange`s with IN message. The processing steps along the route can modify the IN message and ultimately populate the OUT message that is used by the consumer endpoint as a response (imagine the IN/OUT pattern as a mapping of the Request/Response pattern)

###`Message`
The IN/OUT `Message`s in the exchange have a standard structure, being constituted of header, body and attachments. The processing steps can read or modify freely each of these parts, being all these mutable structures.

###`ProducerTemplate`
In testing scenarios, or in situations where messages are not consumed from a Camel endpoint, you might want to create an Exchange and send it to an endpoint. This can happen e.g. when you are integrating Camel in an existing web  application, and you want to use it to handle only one part of the request/response cycle, delegating the final handling to the existing framework or container. Moreover, you want to be completely sure of not ending up in thread safety problems. 
For these cases the `CamelContext` provides with an instance of `ProducerTemplate` which allows to ultimately synthesize on the flight an `Exchange` and send it to an endpoint, all in a _thread safe manner_. `ProducerTemplate` provides a number of methods to build an `Exchange`.