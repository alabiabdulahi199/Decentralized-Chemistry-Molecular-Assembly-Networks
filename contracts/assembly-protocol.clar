;; Assembly Protocol Contract
;; Manages molecular construction processes and protocols

(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOT_FOUND (err u201))
(define-constant ERR_INVALID_PROTOCOL (err u202))
(define-constant ERR_LAB_NOT_VERIFIED (err u203))

;; Assembly protocol structure
(define-map assembly-protocols
  { protocol-id: uint }
  {
    name: (string-ascii 100),
    creator: principal,
    lab-id: uint,
    molecular-formula: (string-ascii 200),
    assembly-steps: uint,
    temperature-range: { min: uint, max: uint },
    pressure-range: { min: uint, max: uint },
    duration-minutes: uint,
    safety-level: uint,
    success-rate: uint,
    created-at: uint,
    status: (string-ascii 20)
  }
)

;; Assembly execution records
(define-map assembly-executions
  { execution-id: uint }
  {
    protocol-id: uint,
    executor: principal,
    lab-id: uint,
    start-time: uint,
    end-time: uint,
    success: bool,
    yield-percentage: uint,
    notes: (string-ascii 500)
  }
)

(define-data-var protocol-counter uint u0)
(define-data-var execution-counter uint u0)

;; Create new assembly protocol
(define-public (create-protocol
  (name (string-ascii 100))
  (lab-id uint)
  (molecular-formula (string-ascii 200))
  (assembly-steps uint)
  (temp-min uint) (temp-max uint)
  (pressure-min uint) (pressure-max uint)
  (duration-minutes uint)
  (safety-level uint)
)
  (let ((protocol-id (+ (var-get protocol-counter) u1)))
    ;; Verify lab exists and is verified (simplified check)
    (if (> lab-id u0)
      (begin
        (map-set assembly-protocols
          { protocol-id: protocol-id }
          {
            name: name,
            creator: tx-sender,
            lab-id: lab-id,
            molecular-formula: molecular-formula,
            assembly-steps: assembly-steps,
            temperature-range: { min: temp-min, max: temp-max },
            pressure-range: { min: pressure-min, max: pressure-max },
            duration-minutes: duration-minutes,
            safety-level: safety-level,
            success-rate: u0,
            created-at: block-height,
            status: "active"
          }
        )
        (var-set protocol-counter protocol-id)
        (ok protocol-id)
      )
      ERR_INVALID_PROTOCOL
    )
  )
)

;; Execute assembly protocol
(define-public (execute-protocol (protocol-id uint) (lab-id uint))
  (let (
    (protocol (unwrap! (map-get? assembly-protocols { protocol-id: protocol-id }) ERR_NOT_FOUND))
    (execution-id (+ (var-get execution-counter) u1))
  )
    (map-set assembly-executions
      { execution-id: execution-id }
      {
        protocol-id: protocol-id,
        executor: tx-sender,
        lab-id: lab-id,
        start-time: block-height,
        end-time: u0,
        success: false,
        yield-percentage: u0,
        notes: ""
      }
    )
    (var-set execution-counter execution-id)
    (ok execution-id)
  )
)

;; Complete assembly execution
(define-public (complete-execution (execution-id uint) (success bool) (yield-percentage uint) (notes (string-ascii 500)))
  (let ((execution (unwrap! (map-get? assembly-executions { execution-id: execution-id }) ERR_NOT_FOUND)))
    (if (is-eq tx-sender (get executor execution))
      (begin
        (map-set assembly-executions
          { execution-id: execution-id }
          (merge execution {
            end-time: block-height,
            success: success,
            yield-percentage: yield-percentage,
            notes: notes
          })
        )
        (ok true)
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Get protocol details
(define-read-only (get-protocol (protocol-id uint))
  (map-get? assembly-protocols { protocol-id: protocol-id })
)

;; Get execution details
(define-read-only (get-execution (execution-id uint))
  (map-get? assembly-executions { execution-id: execution-id })
)
