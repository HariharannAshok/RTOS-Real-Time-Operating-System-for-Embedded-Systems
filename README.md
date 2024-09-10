# RTOS: Real-Time Operating System for Embedded Systems

## Overview
This project implements a custom Real-Time Operating System (RTOS) designed for embedded applications. The system supports multitasking, time-slicing, task scheduling, and synchronization using mutexes. It was developed as part of a university course in Embedded Systems and executed in the Easy68K simulator.

## Key Features
- **Multitasking**: Multiple tasks run concurrently, managed by the RTOS scheduler.
- **Round-Robin Scheduling**: Ensures fair allocation of CPU time across tasks.
- **Mutex Synchronization**: Provides mutual exclusion to shared resources, preventing race conditions.
- **Wait Time Handling**: Tasks can be delayed and scheduled based on wait times, managed by the RTOS.
- **Task Control Block (TCB)**: Each task is represented by a TCB containing the task’s status, registers, and memory locations.
- **System Calls**: Includes system calls for creating and deleting tasks, managing synchronization, and handling wait times.

## Technologies Used
- **Assembly Language**: Low-level programming for task management and system calls.
- **Easy68K Simulator**: A platform for simulating the 68000 microprocessor, used for developing and testing the RTOS.
- **Task Control Block (TCB)**: For tracking the state and context of tasks.
- **Mutex Synchronization**: Manages resource sharing in a multitasking environment.
- **Microcontroller Programming**: Interfaces with hardware peripherals.

## How It Works
1. **Task Creation and Scheduling**: Tasks are initialized with specific stack memory and a program counter. The round-robin scheduler ensures fair CPU time distribution.
2. **Mutex-Based Synchronization**: Tasks use mutexes to control access to critical sections, ensuring safe and synchronized multitasking.
3. **Wait Time Management**: Tasks can be delayed for a specified duration, and the scheduler efficiently manages task switching when wait times expire.

## Memory Layout
The RTOS memory layout includes Task Control Blocks (TCBs) for each task, user task memory, and stack memory. Tasks are managed and scheduled by the RTOS, ensuring efficient memory usage and task management.

## Usage
To use the RTOS in your embedded application:
1. Include the RTOS header file in your assembly project.
2. Define your tasks and their respective functions.
3. Create tasks using the RTOS system calls.
4. Start the RTOS scheduler to manage task execution.

## Examples
Here are a few simple examples of tasks that can be created using the RTOS:

### Example Task
```assembly
Task1:
    ; Task code here
    bra Task1 ; Loop back to Task1

Task2:
    ; Task code here
    bra Task2 ; Loop back to Task2

; In main function
jsr CreateTask(Task1, 1)
jsr CreateTask(Task2, 2)
jsr StartScheduler



