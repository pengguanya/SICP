#lang sicp

;; ---- helper functions ----;
(define (square x)
  (* x x))

;; ---- define put and get ----;
(define global-array '())

(define (make-entry k v) (list k v))
(define (key entry) (car entry))
(define (value entry) (cadr entry))

(define (put op type item)
  (define (put-helper k array)
    (cond ((null? array) (list(make-entry k item)))
          ((equal? (key (car array)) k) array)
          (else (cons (car array) (put-helper k (cdr array))))))
  (set! global-array (put-helper (list op type) global-array)))

(define (get op type)
  (define (get-helper k array)
    (cond ((null? array) #f)
          ((equal? (key (car array)) k) (value (car array)))
          (else (get-helper k (cdr array)))))
  (get-helper (list op type) global-array))

; ---- define attach tag ----;
(define (attach-tag type-tag contents)
  (cons type-tag contents))

(define (type-tag datum)
  (if (pair? datum)
      (car datum)
      (error "Bad tagged datum -- TYPE-TAG" datum)))

(define (contents datum)
  (if (pair? datum)
      (cdr datum)
      (error "Bad tagged datum -- CONTENTS" datum)))

;; ---- scheme-number package 
(define (install-scheme-number-package)
  (define (tag x)
    (attach-tag 'scheme-number x))
  (put 'add '(scheme-number scheme-number)
       (lambda (x y) (tag (+ x y))))
  (put 'sub '(scheme-number scheme-number)
       (lambda (x y) (tag (- x y))))
  (put 'div '(scheme-number scheme-number)
       (lambda (x y) (tag (/ x y))))
  (put 'mul '(scheme-number scheme-number)
       (lambda (x y) (tag (* x y))))
  (put 'make 'scheme-number (lambda (x) (tag x)))
  'done)

;(install-scheme-number-package)
;(define (make-scheme-number n)
;  ((get 'make 'scheme-number) n))
;
;(define x (make-scheme-number 5))
;
;(display (type-tag x))
;(newline)
;(display (contents x))

;; ---- rational number package
(define (install-rational-package)
  ;; internal procedures
  (define (numer x) (car x))
  (define (denom x) (cdr x))
  (define (make-rat n d)
    (let ((g (gcd n d)))
      (cons (/ n g) (/ d g))))
  (define (add-rat x y)
    (make-rat (+ (* (numer x) (denom y))
                 (* (numer y) (denom x)))
              (* (denom x) (denom y))))
  (define (sub-rat x y)
    (make-rat (- (* (numer x) (denom y))
                 (* (numer y) (denom x)))
              (* (denom x) (denom y))))
  (define (mul-rat x y)
    (make-rat (* (numer x) (numer y))
              (* (denom x) (denom y))))
  (define (div-rat x y)
    (make-rat (* (numer x) (denom y))
              (* (denom x) (numer y))))
  ;; interface to rest of the system
  (define (tag x) (attach-tag 'rational x))
  (put 'add '(rational rational)
       (lambda (x y) (tag (add-rat x y))))
  (put 'sub '(rational rational)
       (lambda (x y) (tag (sub-rat x y))))
  (put 'mul '(rational rational)
       (lambda (x y) (tag (mul-rat x y))))
  (put 'div '(rational rational)
       (lambda (x y) (tag (div-rat x y))))
  (put 'make 'rational
       (lambda (n d) (tag (make-rat n d))))
  'done
  )

;; ---- rectangular number package
(define (install-rectangular-package)
  ;; internal procedures
  (define (real-part-1 z) (car z))
  (define (imag-part-1 z) (cdr z))
  (define (make-from-real-imag x y) (cons x y))
  (define (magnitude-1 z)
    (sqrt (+ (square (real-part-1 z))
             (square (imag-part-1 z)))))
  (define (angle-1 z)
    (atan (imag-part-1 z) (real-part-1 z)))
  (define (make-from-mag-ang r a) 
    (cons (* r (cos a)) (* r (sin a))))
  ;; interface to the rest of the system
  (define (tag x) (attach-tag 'rectangular x))
  (put 'real-part-1 '(rectangular) real-part-1)
  (put 'imag-part-1 '(rectangular) imag-part-1)
  (put 'magnitude-1 '(rectangular) magnitude-1)
  (put 'angle-1 '(rectangular) angle-1)
  (put 'make-from-real-imag 'rectangular 
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'rectangular 
       (lambda (r a) (tag (make-from-mag-ang r a))))
  'done)

;; ---- polor number package
(define (install-polar-package)
  ;; internal procedures
  (define (magnitude-1 z) (car z))
  (define (angle-1 z) (cdr z))
  (define (make-from-mag-ang r a) (cons r a))
  (define (real-part-1 z)
    (* (magnitude-1 z) (cos (angle-1 z))))
  (define (imag-part-1 z)

    (* (magnitude-1 z) (sin (angle-1 z))))
  (define (make-from-real-imag x y) 
    (cons (sqrt (+ (square x) (square y)))
          (atan y x)))
  ;; interface to the rest of the system
  (define (tag x) (attach-tag 'polar x))
  (put 'real-part-1 '(polar) real-part-1)
  (put 'imag-part-1 '(polar) imag-part-1)
  (put 'magnitude-1 '(polar) magnitude-1)
  (put 'angle-1 '(polar) angle-1)
  (put 'make-from-real-imag 'polar
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'polar 
       (lambda (r a) (tag (make-from-mag-ang r a))))
  'done)

(define (apply-generic op . args)
  (let ((type-tags (map type-tag args)))
    (let ((proc (get op type-tags)))
      (if proc
          (apply proc (map contents args))
          (error
           "No method for these types -- APPLY-GENERIC"
           (list op type-tags))))))

;; ---- complex number package
(install-polar-package)
(install-rectangular-package)

(define (install-complex-package)
  ;; imported procedures from rectangular and polar packages)
  (define (make-from-real-imag x y)
    ((get 'make-from-real-imag 'rectangular) x y))
  (define (make-from-mag-ang r a)
    ((get 'make-from-mag-ang 'polar) r a))
  ;; internal procedures
  (define (add-complex z1 z2)
    (make-from-real-imag (+ (real-part-1 z1) (real-part-1 z2))
                         (+ (imag-part-1 z1) (imag-part-1 z2))))
  (define (sub-complex z1 z2)
    (make-from-real-imag (- (real-part-1 z1) (real-part-1 z2))
                         (- (imag-part-1 z1) (imag-part-1 z2))))
  (define (mul-complex z1 z2)
    (make-from-mag-ang (* (magnitude-1 z1) (magnitude-1 z2))
                       (+ (angle-1 z1) (angle-1 z2))))
  (define (div-complex z1 z2)
    (make-from-mag-ang (/ (magnitude-1 z1) (magnitude-1 z2))
                       (- (angle-1 z1) (angle-1 z2))))
  ;; interface to rest of the system
  (define (tag z) (attach-tag 'complex z))
  (put 'add '(complex complex)
       (lambda (z1 z2) (tag (add-complex z1 z2))))
  (put 'sub '(complex complex)
       (lambda (z1 z2) (tag (sub-complex z1 z2))))
  (put 'mul '(complex complex)
       (lambda (z1 z2) (tag (mul-complex z1 z2))))
  (put 'div '(complex complex)
       (lambda (z1 z2) (tag (div-complex z1 z2))))
  (put 'make-from-real-imag 'complex
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'complex
       (lambda (r a) (tag (make-from-mag-ang r a))))
  (put 'magnitude-1 '(complex) magnitude-1)
  ;(put 'real-part-1 '(complex) real-part-1)
  ; even do not put real-part-1, generic add/sub/mul/div will work with complex number
  ; because the first time apply-generic applied, the complex tag is stripped out
  ; add-complex then only see the inner tags of rectangular or polar
  (put 'angle-1 '(complex) angle-1) 
  'done)

(define (real-part-1 x) (apply-generic 'real-part-1 x))
(define (imag-part-1 x) (apply-generic 'imag-part-1 x))
(define (magnitude-1 z) (apply-generic 'magnitude-1 z))
(define (angle-1 x) (apply-generic 'angle-1 x))

(define (make-complex-from-real-imag x y)
  ((get 'make-from-real-imag 'complex) x y))

(define (make-complex-from-mag-ang r a)
  ((get 'make-from-mag-ang 'complex) r a))

(install-complex-package)

(define x ((get 'make-from-real-imag 'rectangular) 3 4))
(real-part-1 x)
(define y ((get 'make-from-mag-ang 'polar) 6 2))
(define z (make-complex-from-real-imag 3 4))
(define v (make-complex-from-real-imag 2 5))
(define w (make-complex-from-mag-ang 9 10))

; test magnitude-1
(magnitude-1 x)
(newline)
(magnitude-1 y)
;(magnitude-1 z) ; without put in complex package, print "No method for these types -- APPLY-GENERIC {magnitude-1 {complex}}
(display z)
(newline)
(magnitude-1 z)

; test add
(define (add a b) (apply-generic 'add a b))
(display z)
(newline)
(display v)
(newline)
(display (add v z))
(newline)
(display (add v w))

; test div
(define (div a b) (apply-generic 'div a b))
(display z)
(newline)
(display v)
(newline)
(display (div v z))
(newline)
(display (div v w))
;(display global-array) 
