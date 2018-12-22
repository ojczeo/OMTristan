(in-package :om)


; ===========   fonctions utiles     ========================

; om-mean ne marche que sur des listes simples
(defmethod! tm-average ((liste list) &optional (weights 1))
  :initvals (list '(1 3 5) 1) 
  :indoc '("list of numbers" "list of numbers") 
  :icon 136
  :doc "like om-mean, but accepts trees"
  (less-tree-mapcar (function average) liste weights))



; ---------------pour compatibilit�-----------------

(defun l-nth (list positions)
  (posn-match list positions))


; ---------------------------------------------------

(defun car! (thing)
  "Returns (caa...ar <thing>).  Applies #'car as many times as possible (maybe 0)."
  (ifnot (consp thing) thing (car! (car thing))))


(defun carlist! (thing)
  "Returns an atom if thing is an atom or a one-element list,
   otherwise returns the list unchanged "
   (if (and (consp thing) (= (length thing) 1)) (car! thing) thing))



(defun double-mapcar (fun1 list1? list2? &rest args)
  "Mapcars <fun> or applies <fun1> to <list1?> <list2?> <args>
whether each of <list1?> <list2?> is a list or not."
   (cond
    ((consp list1?)
     (if (consp list2?)
       ;(error "cannot double-mapcar 2 lists: ~S and ~S~%." list1? list2?)
       (mapcar #'(lambda (x1 x2) (apply fun1 x1 x2 args))
               list1? list2?)
       (mapcar #'(lambda (x) (apply fun1 x list2? args))
               list1?)))
    ((consp list2?)
     (mapcar #'(lambda (x) (apply fun1 list1? x args))
             list2?))
    (t (apply fun1 list1? list2? args))))


(defmethod arith-tree-mapcar ((fun function) (arg1 number) (arg2 number) &optional accumulator)
  (if accumulator (reverse (cons (funcall fun arg1 arg2) accumulator)) (funcall fun arg1 arg2)))

(defmethod arith-tree-mapcar ((fun function) (arg1 cons) (arg2 number) &optional accumulator)
  (arith-tree-mapcar fun (cdr arg1) arg2 (cons (arith-tree-mapcar fun (car arg1) arg2) accumulator)))

(defmethod arith-tree-mapcar ((fun function) (arg1 null) arg2 &optional accumulator)
  (declare (ignore arg1 arg2)) (reverse accumulator))

(defmethod arith-tree-mapcar ((fun function) (arg1 number) (arg2 cons) &optional accumulator)
  (arith-tree-mapcar fun arg1 (cdr arg2) (cons (arith-tree-mapcar fun arg1 (car arg2)) accumulator)))

(defmethod arith-tree-mapcar ((fun function) arg1 (arg2 null) &optional accumulator)
   (declare (ignore arg1 arg2 )) (reverse accumulator))

(defmethod arith-tree-mapcar ((fun function) (arg1 cons) (arg2 cons) &optional accumulator)
  (arith-tree-mapcar fun (cdr arg1) (cdr arg2)
                     (cons (arith-tree-mapcar fun (car arg1) (car arg2)) accumulator)))


#|
(defmethod LLdecimals ((list t) (nbdec integer))
  "Arrondit liste de profondeur quelconque avec <nbdec> d�cimales"
(let ((ndec 
       (if (> nbdec 0 ) (float (expt 10 nbdec)) (expt 10 nbdec))))
  (deep-mapcar/1 '/  
   (deep-mapcar/1 'round list (/ 1 ndec)) ndec )))
|#


(defun list-fill (list len) 
  "Duplicates the elements of <list> until its length equals <len>."
  (check-type len (integer 0 *) "a positive integer")
  (let* ((length (length (setq list (list! list))))
         ;; len = length*n + r
         (n (floor len length))
         (r (mod len length))
         ;; len = r*(n+1) + (length-r)*n
         (l ()))
    (repeat r
      (repeat (1+ n) (newl l (car list)))
      (nextl list))
    (repeat (- length r)
      (repeat n (newl l (car list)))
      (nextl list))
    (nreverse l)))


(defun unique-1 (lst test ) 
  "returns a copy of the list, dropping duplicate values"
  (cond
   ((null lst) ())
   ((member (car lst) (cdr lst) :test test) (unique-1 (cdr lst) test))
   (t (cons (car lst) (unique-1 (cdr lst) test)))))

(defun unique (lst ) 
  "returns a copy of <lst>, dropping duplicate values (deepest level)"
  (less-deep-mapcar #'(lambda (x) (unique-1 x #'eq)) lst))



(defun LL/round (l1?  div )
  "Rounding of two of numbers or lists."
  (deep-mapcar/1 'round l1? div))


; -------------------------------------------
; fonctions existant d�j� dans Esquisse 


(defun car-mapcar (fun list?  &rest args)
  "Mapcars <fun> if list? is a list or applies <fun> if it is an atom or
a one-element list"
  (cond  ((atom list?) (apply fun list? args))
         ((= (length list?) 1) (apply fun (car list?) args))
         (t (mapcar #'(lambda (x) (apply fun x  args ))  list? ))))

(defun less-deep-mapcar (fun  list? &rest args)
  "Applies <fun> to <list?> <args> if <list?> is a one-level list .
   Mapcars <fun> to <list?> <args> if <list?> is a multi-level list. "
  (cond
    ((null list?) ())
    ((atom (car list?)) (apply fun list? args))
    ((atom (car (car list?))) 
     (cons (apply fun (car list?)  args ) (apply #'less-deep-mapcar fun (cdr list?) args)))
    (t (cons (apply #'less-deep-mapcar fun  (car list?) args)
             (apply #'less-deep-mapcar fun  (cdr list?) args)))))


(defun one-elem (item)
  (or (atom item) (= (length item) 1)))

(defun carlist! (thing)
  "Returns an atom if thing is an atom or a one-element list,
   otherwise returns the list unchanged "
  (if (and (consp thing) (= (length thing) 1)) (car! thing) thing))




#|
;Exists already in OM ???

(defmethod! band-filter+ ((list list) (bounds list) (mode symbol))
  :initvals '('(1 2 3 4 5) '((0 2) (5 10)) 'pass)
  :indoc '("list" "bounds" "mode" )
  :menuins '((2 (("Reject" 'reject) ("Pass" 'pass))))
  :icon 235 
  :doc  "filters out <list> (a list or a tree of numbers) using <bounds>.
<bounds> is a list of pairs (min-value max-value). Elts in list are selected if they stay between the bounds.
<mode> is a menu input. 'Reject' means reject elts that are selected. 
'Pass' means retain only elts that are selected."
  (let ((bounds (if (atom (first bounds)) (list bounds) bounds)))
  (list-filter 
   #'(lambda (item)
       (some #'(lambda (bound) (and (>= item (first bound)) (<= item (second bound)))) bounds))
   list 
   mode)))

|#

; -------------------------------------------
;Keep it finaly for  compatibility
; � r��crire, si n�cessaire

(defun chord->list! (accord)
"teste si type accord ou liste; rend midics"
  (if (typep accord 'list) accord (lmidic  accord )))

; -> donner ce type en entr�e de l'accord : (list (:value () :dialog-item-text "()" :type-list ()))


;Methode � integrer directement ds OpenMusic

(defmethod om-scale/max ((list list) (max number))
"scales <list>  (may be tree) so that its max becomes <max>. Trees must be 
well-formed: The children of a node must be either all leaves or all nonleaves. "
 (less-tree-mapcar #'(lambda (x y) (om* x (/ y (list-max x)))) list max t))

;---------------------------------------------------------------------------------------
;------------------------------------Integres monmentanement-----------------------------
;------------------------pour l'ouverture des patchs joints------------------------------

(defun l-max (list)
  "maximum value(s) of a list or list of numbers"
  (if (not (consp (first list)))
    (apply 'max list)
    (mapcar #'(lambda (x) (apply 'max x)) list)))

(om::defmethod* l-assoc ((format  symbol)
                    (list1 list)  (list2 list) 
                    &rest lst?)

 
   :initvals (list "flat" '(1 2) '(1 2) '(1 2))
   :indoc '("format" "list1" "list2" "other lists")
   :icon 132
   :menuins '((0 (("flat" 'flat) ("struct" 'struct) ("flat-low" 'flat-low))))
   :doc "couple les listes : (1 2 3) (10 11 12) --> (1 10 2 11 3 12)"

  (let* ((listgen (append (list list1 list2) lst?))
         (long (1- (l-max (mapcar #'length listgen)))) res)
    (for (i 0 1 long)
      (push  (car-mapcar #'l-nth listgen i) res))
    (cond  ((equal format 'flat) (flat (nreverse res))) 
           ((equal format 'struct) (nreverse res))
           ((equal format 'flat-low) (flat-low (nreverse res))))))



#|
;librairie-TM.lisp


(defun substit-one (liste  elem val fct)
  (let ((long (1- (length liste) )) (val (list val)))
    (x-append (l-nth liste (arithm-ser 0 (1- elem) 1))
          (if (equal fct '=) val (funcall fct (l-nth liste elem) val ))
          (l-nth liste (arithm-ser (1+ elem) long 1)) )))

(defmethod substit ((liste list) (elem list) (val list) 
                    &optional (fct '=))

   :initvals (list '(1 2) '(1 2) "name" '=)
   :indoc '("liste" "elem" "val" "fct" )
   :icon 132
   :doc "remplace les �l�ments de n� <elem> par les valeurs <val>
         extension: <fct> = fonction ; si <fct> diff�rent de  ''='',
         on remplace alors par (  <fct>   <val.ancienne>   <val>  )"


  (let* ((elem (list! elem))  (lg (1- (length elem)))
         (val (if (and (consp val) (one-elem elem)) (list val) (list! val))))
    (for (n 0 1 lg)
      (setq liste (substit-one liste (l-nth elem n) (l-nth val n) fct)))
    liste))
|#


;--------------------------------------lfa->coll------------------------------------------------




















