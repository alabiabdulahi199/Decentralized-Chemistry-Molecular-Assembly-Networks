;; Laboratory Verification Contract
;; Validates molecular assembly systems and laboratory credentials

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))

;; Laboratory data structure
(define-map laboratories
  { lab-id: uint }
  {
    name: (string-ascii 100),
    certification-level: uint,
    verified: bool,
    verification-date: uint,
    equipment-rating: uint,
    safety-score: uint
  }
)

;; Verification records
(define-map verification-records
  { lab-id: uint, verification-id: uint }
  {
    verifier: principal,
    timestamp: uint,
    status: (string-ascii 20),
    notes: (string-ascii 500)
  }
)

(define-data-var lab-counter uint u0)
(define-data-var verification-counter uint u0)

;; Register a new laboratory
(define-public (register-laboratory (name (string-ascii 100)) (equipment-rating uint) (safety-score uint))
  (let ((lab-id (+ (var-get lab-counter) u1)))
    (map-set laboratories
      { lab-id: lab-id }
      {
        name: name,
        certification-level: u1,
        verified: false,
        verification-date: block-height,
        equipment-rating: equipment-rating,
        safety-score: safety-score
      }
    )
    (var-set lab-counter lab-id)
    (ok lab-id)
  )
)

;; Verify laboratory
(define-public (verify-laboratory (lab-id uint) (certification-level uint))
  (let ((lab (unwrap! (map-get? laboratories { lab-id: lab-id }) ERR_NOT_FOUND)))
    (if (is-eq tx-sender CONTRACT_OWNER)
      (begin
        (map-set laboratories
          { lab-id: lab-id }
          (merge lab { verified: true, certification-level: certification-level, verification-date: block-height })
        )
        (ok true)
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Get laboratory info
(define-read-only (get-laboratory (lab-id uint))
  (map-get? laboratories { lab-id: lab-id })
)

;; Check if laboratory is verified
(define-read-only (is-laboratory-verified (lab-id uint))
  (match (map-get? laboratories { lab-id: lab-id })
    lab (get verified lab)
    false
  )
)
