# Tower

`Tower` is an error handler based on the new BEAM `logger`, which was introduced in OTP 21 and
fully integrated into `Elixir`'s `Logger` in Elixir v1.15. Reason why `Tower` requires
Elixir `~> 1.15`.

## Nomenclature/Glossary/Terminology

### error_logger

Erlang [error_handler](https://www.erlang.org/doc/apps/kernel/error_logger)

### logger

Erlang [logger](https://www.erlang.org/doc/apps/kernel/logger)

#### logger handler

Erlang [logger_handler](https://www.erlang.org/doc/apps/kernel/logger_handler)

### Logger

Elixir `Logger` built on top of the Erlang logger.

### Errors

https://www.erlang.org/doc/system/errors.html#terminology

#### Run-time errors

When a crash occurs.
An example is when an operator is applied to arguments of the wrong type.i
The Erlang programming language has built-in features for handling of run-time errors.
A run-time error can also be emulated by calling error(Reason).
Run-time errors are exceptions of class `:error`.

#### Generated errors

When the code itself calls `exit/1` or `throw/1`. Generated errors are exceptions of class `:exit` or `:throw`.

##### Exits

###### Abnormal exit

###### Normal exit

### Capturing/Handling

### Event

`Tower.Event`

### error class

Erlang error "type"

### error kind

Elixir error "type"

## What is an error in Elixir?

## Why

De-couple capturing from reporting. Capturing is specific to the runtime and programming language. Reporting is specific to a SaaS or other
other system that stores error events.
Implement capturing once well, and reporting multiple times depending on the target.
1 handler N reporters

One capturer/handler means multiple reporters benefits from 1 central location we adapt to erlang/elixir future changes.
Try to move closer to a "standard" way of capturing errors in Elixir despite specifics of reporting target.

Logger Handler centric:
Less chance of double-capturing.

## How it works

Listens to all logger events.
Reports all exceptions, throws and abnormal exits.
Also recognizes message logging.
Reports those above configured level (default critical).


## ====

Atomic capturing
Logger handler centric
Protect from sensitive data by excluding by default
