---
layout: post
title: "Parallelizing is not for free"
date: 2015-01-27 23:27:37 +0100
comments: true
categories: [Java, Concurrency, Threads] 
---

####Why learning concurrency
Studying for the OCP exam offers a nice opportunity to dive into one of the most important (and sometimes overlooked) aspects of the Java language and JVM: threads and concurrency frameworks.
Before I never delved into the details about concurrency just because I have been working on the soft pillow of a container (like Tomcat) or of a framework (like Apache Camel) that takes care of distributing load on a thread pool, and basically every request or every message processing can in 99% of cases be treated as a synchronous process, so I survived for many years without having a good understanding of the .

Learning how threads and concurrency works is important especially if we look at how hardware is evolving. Processors speed is not increasing any more (due to physical limitations) but processors are getting *fat*, i.e. the number of cores is constantly increasing, and we must be able to make best use of them.

####Threads in Java
When we talk about threads a distinction must be made between a *thread as object* and a *thread of execution*. Java has supported threads since the very beginning in a native way. As everything in Java is handled as an object, threads are not an exception, and a thread is represented by the `java.lang.Thread` class. A thread of execution instead represents a call stack that is being executed on the JVM. You can visualize multiple threads running as many call stacks running independently. However threads can possibly work on the same objects in the Heap, and there are a number of mechanisms provided within the language to allow handling in a safe way these shared objects (synchronized blocks and methods, locks, read/write locks, atomic variables).
I used to think myself that parallelizing things could lead automatically to better performance, but after diving a bit into the subject, I came across a great presentation from Martin Thompson that I really recommend (https://www.youtube.com/watch?v=4dfk3ucthN8). This presentation is great for a couple of reasons, first it makes it clear that having knowledge about the general structure of the machine on  which our programs run is paramount to have efficient code. We don't need to know all the details as if we are developing firmware code for a particular processor, but a general understanding of how modern multicore CPUs work is recommended (*mechanical sympathy*). Secondly, it conveys the important concept that having threads contending a certain resource and swapping context take time, and it might be not always convenient to parallelize. So *parallelize with a grain of salt*. 

####Benchmark
To convince myself of the fact that parallelization is not necessarily good,  I used the same example suggested in the [Disruptor presentation](http://lmax-exchange.github.io/disruptor/files/Disruptor-1.0.pdf), a very trivial problem which is incrementing an `int` variable 10.000.000 times. The aim is to compare the performance of these approaches in dealing with this problem.
The different approaches to perform this are:

######Single threaded, with a while loop
This is the most trivial approach:

``` Java
while (i < times) {
    i++;
}
```
The while loop is executed on one single core. 

######Single threaded, with a lock/unlock within the loop
To measure the price of a simple lock and unlock, without any other thread involved in it, so no contention, I used this second strategy


``` Java
while (i < times) {
    lock.lock();
    i++;
    lock.unlock();
}
```