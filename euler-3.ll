; The prime factors of 13195 are 5, 7, 13 and 29.
; 
; What is the largest prime factor of the number 600851475143 ?

declare i32 @printf(i8*, ...)
declare i64 @atol(i8*)
declare i8* @memcpy(i8*, i8*, i64)
declare double @llvm.sqrt.f64(double)
declare void @free(i8*)
declare i8* @malloc(i64)

@print.i64.format = private unnamed_addr constant [5 x i8] c"%lu\0A\00"
define i32 @print.i64(i64 %to-print) #0 {
  %ret = call i32 (i8*, ...) @printf(
    i8* getelementptr inbounds (
      [5 x i8],
      [5 x i8]* @print.i64.format,
      i32 0,
      i32 0
    ),
    i64 %to-print
  )

  ret i32 %ret
}

; Returns the truncated square root of an integer
define i64 @sqrt.i64(i64 %n) #0 {
  %n.f64 = uitofp i64 %n to double
  %sqrt = call double @llvm.sqrt.f64(double %n.f64)
  %sqrt.i64 = fptoui double %sqrt to i64
  ret i64 %sqrt.i64
}

%array.i64 = type { i16, i64* }
%option.i64 = type { i1, i64 }
%option.array.i64 = type { i1, %array.i64 }

define %array.i64 @append.i64(%array.i64 %first, %array.i64 %second) #0 {
  %first-len = extractvalue %array.i64 %first, 0
  %first-null.cond = icmp eq i16 %first-len, 0
  br i1 %first-null.cond, label %first-null, label %first-not-null
first-null:
  ret %array.i64 %second
first-not-null:
  %second-len = extractvalue %array.i64 %second, 0
  %second-null.cond = icmp eq i16 %second-len, 0
  br i1 %second-null.cond, label %second-null, label %second-not-null
second-null:
  ret %array.i64 %first
second-not-null:
  %Size.pointer = getelementptr inbounds i64, i64* null, i32 1
  %Size.i64 = ptrtoint i64* %Size.pointer to i64

  %first-len.i32 = zext i16 %first-len to i32
  %first-len.i64 = zext i32 %first-len.i32 to i64
  %first-len-bytes = mul i64 %first-len.i64, %Size.i64

  %second-len.i64 = zext i16 %second-len to i64
  %second-len-bytes = mul i64 %second-len.i64, %Size.i64

  %out-len = add i16 %first-len, %second-len
  %out-len.i64 = zext i16 %out-len to i64
  %out-byte-size = mul i64 %out-len.i64, %Size.i64

  %first-target.void = call i8* (i64) @malloc(i64 %out-byte-size)
  %first-target = bitcast i8* %first-target.void to i64*

  %second-target = getelementptr inbounds
    i64,
    i64* %first-target,
    i32 %first-len.i32
  %second-target.void = bitcast i64* %second-target to i8*

  %first-pointer = extractvalue %array.i64 %first, 1
  %second-pointer = extractvalue %array.i64 %second, 1
  %first-pointer.void = bitcast i64* %first-pointer to i8*
  %second-pointer.void = bitcast i64* %second-pointer to i8*

  call i8* (i8*, i8*, i64) @memcpy(
    i8* %first-target.void,
    i8* %first-pointer.void,
    i64 %first-len-bytes
  )

  call i8* (i8*, i8*, i64) @memcpy(
    i8* %second-target.void,
    i8* %second-pointer.void,
    i64 %second-len-bytes
  )

  call void (i8*) @free(i8* %first-pointer.void)
  call void (i8*) @free(i8* %second-pointer.void)

  %out1 = insertvalue %array.i64 undef, i16 %out-len, 0
  %out2 = insertvalue %array.i64 %out1, i64* %first-target, 1
  ret %array.i64 %out2
}

define %array.i64 @singleton.i64(i64 %value) #0 {
  %Size.pointer = getelementptr inbounds i64, i64* null, i32 1
  %Size.i64 = ptrtoint i64* %Size.pointer to i64

  %target.void = call i8* (i64) @malloc(i64 %Size.i64)
  %target = bitcast i8* %target.void to i64*

  store i64 %value, i64* %target

  %out = insertvalue %array.i64 { i16 1, i64* undef }, i64* %target, 1
  ret %array.i64 %out
}

define %array.i64 @get-prime-factors(i64 %n) #0 {
  %div = alloca i64
  %start.i64 = call i64 (i64) @sqrt.i64(i64 %n)
  store i64 %start.i64, i64* %div
  br label %loop.head
loop.head:
  %loop.head.div = load i64, i64* %div
  %loop.head.cond = icmp ne i64 %loop.head.div, 1
  br i1 %loop.head.cond, label %loop.body, label %loop.cont
loop.body:
  %remainder = urem i64 %n, %loop.head.div
  %loop.body.if.cond = icmp eq i64 %remainder, 0
  br i1 %loop.body.if.cond, label %loop.body.if.then, label %loop.body.if.cont
loop.body.if.then:
  %other = udiv i64 %n, %loop.head.div
  %div-factors = call %array.i64 (i64) @get-prime-factors(i64 %loop.head.div)
  %other-factors = call %array.i64 (i64) @get-prime-factors(i64 %other)

  %appended = call %array.i64 @append.i64(
    %array.i64 %div-factors,
    %array.i64 %other-factors
  )
  ret %array.i64 %appended
loop.body.if.cont:
  %next-div = sub i64 %loop.head.div, 1
  store i64 %next-div, i64* %div
  br label %loop.head
loop.cont:
  ; HACK: We should really be doing this with %option.array.i64
  %singleton = call %array.i64 (i64) @singleton.i64(i64 %n)
  ret %array.i64 %singleton
}

; HACK: Only accepts non-zero-length arrays, will loop until it segfaults
;       otherwise
define i64 @max.i64(%array.i64 %arr) #0 {
  %len = extractvalue %array.i64 %arr, 0
  %array-ptr = extractvalue %array.i64 %arr, 1

  %first-ptr =
    getelementptr inbounds i64, i64* %array-ptr, i16 0
  %first = load i64, i64* %first-ptr

  %max = alloca i64
  store i64 %first, i64* %max

  %n = alloca i16
  store i16 1, i16* %n

  br label %loop.head
loop.head:
  %loop.head.n = load i16, i16* %n
  %loop.head.cond = icmp ne i16 %loop.head.n, %len
  br i1 %loop.head.cond, label %loop.body, label %loop.cont
loop.body:
  %current-ptr = getelementptr inbounds i64, i64* %array-ptr, i16 %loop.head.n
  %current = load i64, i64* %current-ptr
  %cur-max = load i64, i64* %max
  %loop.body.if.cond = icmp ugt i64 %current, %cur-max
  br i1 %loop.body.if.cond, label %loop.body.if.then, label %loop.body.if.cont
loop.body.if.then:
  store i64 %current, i64* %max
  br label %loop.body.if.cont
loop.body.if.cont:
  %next = add i16 %loop.head.n, 1
  store i16 %next, i16* %n
  br label %loop.head
loop.cont:
  %out = load i64, i64* %max
  ret i64 %out
}

define void @print-all.i64(%array.i64 %arr) #0 {
  %len = extractvalue %array.i64 %arr, 0
  %array-ptr = extractvalue %array.i64 %arr, 1

  %n = alloca i16
  store i16 0, i16* %n

  br label %loop.head
loop.head:
  %loop.head.n = load i16, i16* %n
  %loop.head.cond = icmp ne i16 %loop.head.n, %len
  br i1 %loop.head.cond, label %loop.body, label %loop.cont
loop.body:
  %current-ptr = getelementptr inbounds i64, i64* %array-ptr, i16 %loop.head.n
  %current = load i64, i64* %current-ptr
  call i32 (i64) @print.i64(i64 %current)
  %next = add i16 %loop.head.n, 1
  store i16 %next, i16* %n
  br label %loop.head
loop.cont:
  ret void
}

define i64 @input-or-default(i32 %argc, i8** %argv, i64 %default) #0 {
  %if.cond = icmp ugt i32 %argc, 1
  br i1 %if.cond, label %if.then, label %if.else
if.then:
  %value-ptr = getelementptr inbounds i8*, i8** %argv, i64 1
  %value = load i8*, i8** %value-ptr
  %out = call i64 (i8*) @atol(i8* %value)
  ret i64 %out
if.else:
  ret i64 %default
}

@main.print-all = private unnamed_addr constant
  [14 x i8] c"All factors:\0A\00"
@main.print-one = private unnamed_addr constant
  [21 x i8] c"Largest factor: %lu\0A\00"
@main.print-false = private unnamed_addr constant [12 x i8] c"It's prime\0A\00"
define i32 @main(i32 %argc, i8** %argv) #0 {
  %value =
    call i64 (i32, i8**, i64) @input-or-default(
      i32 %argc,
      i8** %argv,
      i64 600851475143
    )
  %factors = call %array.i64 (i64) @get-prime-factors(i64 %value)
  %len = extractvalue %array.i64 %factors, 0
  %is-some = icmp ne i16 %len, 0
  br i1 %is-some, label %if.then, label %if.else
if.then:
  call i32 (i8*, ...) @printf(
    i8* getelementptr inbounds (
      [14 x i8],
      [14 x i8]* @main.print-all,
      i32 0,
      i32 0
    )
  )
  call void (%array.i64) @print-all.i64(%array.i64 %factors)

  %highest-val = call i64 (%array.i64) @max.i64(%array.i64 %factors)
  call i32 (i8*, ...) @printf(
    i8* getelementptr inbounds (
      [21 x i8],
      [21 x i8]* @main.print-one,
      i32 0,
      i32 0
    ),
    i64 %highest-val
  )
  br label %if.cont
if.else:
  call i32 (i8*, ...) @printf(
    i8* getelementptr inbounds (
      [12 x i8],
      [12 x i8]* @main.print-false,
      i32 0,
      i32 0
    )
  )
  br label %if.cont
if.cont:
  ret i32 0
}

attributes #0 = {
  nounwind
}
