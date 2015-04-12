---
layout: post
title: "Scala.js for dynamic systems simulation"
date: 2015-04-12 10:13:14 +0200
comments: true
categories: 
---
 After the Scaladays SF 2015 a lot of echo has targeted the [Scala.js](http://www.scala-js.org) framework. Scala.js compiles Scala code into Javascript code, which can be run in a browser but also on Javascript powered server environments e.g. Node.js.

Scala.js is not something like GWT, which provided a whole toolkit for Javascript code generation from Java. Scala.js is simply a compiler that translates Scala code into Javascript code. This allows to use all the great features that make Scala such a successful language, like strong typing, functional code, higher order functions, case classes, pattern matching, and even Future and Promises (when dealing e.g. with events on the client or with Ajax calls). 
For some parts it is possible to develop code that is fully agnostic of the target platform, i.e. you can write some Scala code that can be executed equivalently on a JVM or on a browser when compiled with Scala.js. For the parts that deal with HTML elements or with Ajax, the target platform must be taken into consideration.
The advantage that Scala.js offers is, on top of the pleasure of using a great language like Scala, that due to the strong typing it allows to discover errors already in the compilation phase, while as we know when we develop logic in Javascript, most of the time we discover errors only at runtime.

In this post we will use Scala.js to build a simulator of dynamic systems running on a browser, with the aim to draw a [phase portrait](http://en.wikipedia.org/wiki/Phase_portrait) of a system described by a 2-dimensional [ODE](http://en.wikipedia.org/wiki/Ordinary_differential_equation). For the code please refer to the Github project [https://github.com/pierangeloc/PhasePortraitJS](https://github.com/pierangeloc/PhasePortraitJS).

####SBT project setup
For a full introduction to Scala.js please refer to the great guide [http://lihaoyi.github.io/hands-on-scala-js/](http://lihaoyi.github.io/hands-on-scala-js/). The layout of my project follows exactly the structure outlined in that guide.
To setup an SBT project to use Scala.js you simply must add the corresponding plugin in the `plugins.sbt` file. I added also the [Workbench plugin](https://github.com/lihaoyi/workbench) which proved to be very useful to test your code on the browser:

```Scala
addSbtPlugin("org.scala-js" % "sbt-scalajs" % "0.6.1")

addSbtPlugin("com.lihaoyi" % "workbench" % "0.2.3")
```

In the `build.sbt` file we must enable the `ScalaJSPlugin`  and add the dependency from the scalajs-dom library that allows us to access the DOM elements (and events) from Scala, in a typesafe manner.

```Scala

enablePlugins(ScalaJSPlugin)

libraryDependencies ++= Seq(
  "org.scala-js" %%% "scalajs-dom" % "0.8.0"
)

bootSnippet := "drawing.ScalaJSPhasePortrait().main(document.getElementById('canvas'));"

updateBrowsers <<= updateBrowsers.triggeredBy(fastOptJS in Compile)

```

The `bootSnippet` line is used just to configure Workbench to execute that  Javascript to start the application on the browser, and the `updateBrowsers` line is used to trigger the boot at the end of each compilation phase.  

####Coding
In our `/src/main/scala` project folder we put our Scala codes that will be then compiled into equivalent Javascript. We need to define one or more entry points, i.e. an Scala Object that we want to be translated into a Javascript on which we can invoke one or more methods. Both the Object and the method must be marked properly for export, by means of the `@JSExport` annotation:

```Scala
package drawing

// ...

@JSExport
object ScalaJSPhasePortrait {

  @JSExport
  def realPendulumPhasePortrait(canvas: Canvas): Unit = // ...

  @JSExport
  def simplePendulumPhasePortrait(canvas: Canvas): Unit = // ...

  @JSExport
  def lotkaVolterraPhasePortrait(canvas: Canvas): Unit = // ...
```

Here we are exposing the `drawing.ScalaJSPhasePortrait object` and 3 methods `realPendulumPhasePortrait`,  `simplePendulumPhasePortrait` and `lotkaVolterraPhasePortrait`, each of them expecting a Canvas object as input. The compiler will start from these exposed entities and transitively include everything is *strictly required* by the code in order to function. This means that if a method uses some features provided by another class, possibly provided by a separate library, only the required features are included in the translation package and not the whole library. 

When we run

```bash
 sbt ~fastOptJS
```

we trigger the code generation (the `~` is a standard SBT feature that allows code to be regenerated whenever something changes in the source files). If we inspect the `/target` folder in the project we can see that a file `target/scala-2.11/phaseportraitjs-fastopt.js` has been created. This is the output of the Scala.js compiler. The name of this file is determined by the SBT project name, and this is the file that must be included in our HTML page in order to have our example working. We can then invoke the `drawing.ScalaJSPhasePortrait` object methods from any point in our browser. 

```HTML
<script type="text/javascript" src="../phaseportraitjs-fastopt.js"></script>
<script type="text/javascript" src="/workbench.js"></script>
<script>
    drawing.ScalaJSPhasePortrait().simplePendulumPhasePortrait(document.getElementById('simplePendulum'));
    drawing.ScalaJSPhasePortrait().realPendulumPhasePortrait(document.getElementById('realPendulum'));
    drawing.ScalaJSPhasePortrait().lotkaVolterraPhasePortrait(document.getElementById('lotkaVolterra'));
</script>
```

####The problem

{% verbatim tag:p %}
An autonomous dynamical system in $\mathbb{R}^n$ is described by a system of differential equations that can be represented as:
\[
\dot x = f(x), x \in \mathbb{R}^n
\]

Being the system autonomous means that the field described by the function  $f$ does not depend from time, and this means that the evolution of the movement $x(t)$ given some initial condition $x_0$ depends only from $x_0$ and not from the particular initial time.

This allows us to provide a good description of the evolution of the system by describing the orbits of the sytem, i.e. the values that $x(t)$ assumes regardless of the time. This type of qualitative analysis is important when describing systems for which we don't know an exact solution.
{% endverbatim %}


In our Scala.js application we want to provide a general solution for this problem, for systems of dimension 2, so that their evolution can be easily represented on a 2-dimensional space, in our case an HTML Canvas.

We need to separate the concerns of drawing something on a given rectangle from those of calculating the evolution of a dynamic system.
