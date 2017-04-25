@print.uint = private unnamed_addr constant [4 x i8] c"%u\0A\00"
@multiples  = private constant [2 x i32] [i32 3, i32 5]

declare i32 @printf(i8*, ...)
declare i32 @atoi(i8*)

; i64 for 64 bit platforms
%array.i32 = type { i32, i32* }

define i1 @is-multiple-of-any(i32 %i, i32 %num-mults, i32* %mults) {
  %n = alloca i32
  store i32 0, i32* %n

  br label %loop.head
loop.head:
  %loop.head.n = load i32, i32* %n
  %loop.head.cond = icmp eq i32 %loop.head.n, %num-mults
  br i1 %loop.head.cond, label %loop.cont, label %loop.body
loop.body:
  %loop.body.index = load i32, i32* %n
  %loop.body.pointer = getelementptr inbounds
    i32,
    i32* %mults,
    i32 %loop.body.index
  %loop.body.current-val = load i32, i32* %loop.body.pointer

  %loop.body.remainder = urem i32 %i, %loop.body.current-val
  %loop.body.cond = icmp eq i32 %loop.body.remainder, 0
  br i1 %loop.body.cond, label %return-true, label %loop.body.success
loop.body.success:
  %loop.body.next = add i32 %loop.body.index, 1
  store i32 %loop.body.next, i32* %n
  br label %loop.head
loop.cont:
  br label %return-false
return-false:
  br label %end
return-true:
  br label %end
end:
  %retcode = phi i1 [ false, %return-false ], [ true, %return-true ]
  ret i1 %retcode
}

define i32 @sum-multiples-of(i32 %max, i32 %num-mults, i32* %mults) {
  %tot = alloca i32
  store i32 0, i32* %tot

  %n = alloca i32
  store i32 1, i32* %n

  br label %loop.head
loop.head:
  %loop.head.n = load i32, i32* %n
  %loop.head.cond = icmp eq i32 %loop.head.n, %max
  br i1 %loop.head.cond, label %loop.cont, label %loop.body
loop.body:
  %loop.body.n = load i32, i32* %n 
  %loop.body.if.cond =
    call i1 (i32, i32, i32*) @is-multiple-of-any(
      i32 %loop.body.n,
      i32 %num-mults,
      i32* %mults
    )
  br i1 %loop.body.if.cond, label %loop.body.if.then, label %loop.body.if.cont
loop.body.if.then:
  %loop.body.if.then.tot = load i32, i32* %tot
  %loop.body.if.then.added = add i32 %loop.body.if.then.tot, %loop.body.n
  store i32 %loop.body.if.then.added, i32* %tot
  br label %loop.body.if.cont
loop.body.if.cont:
  %next = add i32 %loop.head.n, 1
  store i32 %next, i32* %n
  br label %loop.head
loop.cont:
  br label %end
end:
  %final-val = load i32, i32* %tot
  ret i32 %final-val
}

define i32 @main(i32 %argc, i8** %argv) {
  %get-max.cond = icmp ugt i32 %argc, 1
  br i1 %get-max.cond, label %get-max.then, label %get-max.else
get-max.then:
  %get-max.then.max-string.pointer =
    getelementptr inbounds i8*, i8** %argv, i32 1
  %get-max.then.max-string = load i8*, i8** %get-max.then.max-string.pointer
  %get-max.then.max = call i32 (i8*) @atoi(i8* %get-max.then.max-string)
  br label %get-max.cont
get-max.else:
  br label %get-max.cont
get-max.cont:
  %below = phi i32
    [ %get-max.then.max, %get-max.then ],
    [ 1000, %get-max.else ]
  %sum = call i32 (i32, i32, i32*) @sum-multiples-of(
    i32 %below,
    i32 2,
    i32* getelementptr inbounds (
      [2 x i32],
      [2 x i32]* @multiples,
      i32 0,
      i32 0
    )
  )
  call i32 (i8*, ...) @printf(
    i8* getelementptr inbounds (
      [4 x i8],
      [4 x i8]* @print.uint,
      i32 0,
      i32 0
    ),
    i32 %sum
  )
  ret i32 0
}
