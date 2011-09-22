; Whitney Music Box in Nyquist -- Jim Bumgardner
(load "pianosyn")

(setf pdur 60.0)
(setf tines 48)
(setf fnote (- 60 (/ tines 2)))
(defun getstart (k n) (* n (/ pdur (+ 1 k))))
(defun getdur   (k n) (/ pdur (+ 1 k )))
(defun getpitch (k n) (+ fnote k))
(defun getvelocity (k n) 50)
(play
  (simrep (k tines)
          (simrep (n (+ 1 k))
                       (at (getstart k n)
                           (piano-note (getdur k n)
                                       (getpitch k n)
                                       (getvelocity k n)
                            )
                        )
           )
  )
)

