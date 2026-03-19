;; ------------------------------------------------------------
;; AGROTOKEN PROTOCOL (ATP)
;; Tokenization of Agricultural Produce into Tradeable Digital Shares
;; Version: 2.0 - Rebranded and Restructured
;; ------------------------------------------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CONSTANTS & ERROR CODES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-constant ERR-NOT-FARMER u100)
(define-constant ERR-INSUFFICIENT-TOKENS u102)
(define-constant ERR-HARVEST-INCOMPLETE u103)
(define-constant ERR-HARVEST-ALREADY-COMPLETED u104)
(define-constant ERR-SALES-CLOSED u105)
(define-constant ERR-NO-TOKENS u106)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; STATE VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Farmer / Contract Owner (initialized on first registration)
(define-data-var farmer principal (as-contract tx-sender))

;; Token metrics
(define-data-var total-supply uint u0)
(define-data-var remaining-supply uint u0)
(define-data-var price-per-token uint u0)

;; Status flags
(define-data-var harvest-completed bool false)
(define-data-var sales-open bool false)

;; Investor token ledger
(define-map balances
  { owner: principal }
  { amount: uint })

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRIVATE EVENTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-private (emit-event (name (string-ascii 32)) (value uint))
  (print { event: name, value: value })
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PUBLIC FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Set the farmer/contract owner
(define-public (set-farmer (new-farmer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get farmer)) (err ERR-NOT-FARMER))
    (asserts! (not (is-eq new-farmer tx-sender)) (err ERR-NOT-FARMER))
    (var-set farmer new-farmer)
    (ok true)
  )
)

;; ------------------------------------------------------------
;; REGISTER PRODUCE and INITIALIZE TOKEN SALE
;; ------------------------------------------------------------

(define-public (register-produce (supply uint) (price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get farmer)) (err ERR-NOT-FARMER))
    (asserts! (> supply u0) (err ERR-NO-TOKENS))
    (asserts! (> price u0) (err ERR-NO-TOKENS))

    (var-set total-supply supply)
    (var-set remaining-supply supply)
    (var-set price-per-token price)
    (var-set sales-open true)

    (emit-event "produce-registered" supply)
    (ok true)
  )
)

;; ------------------------------------------------------------
;; INVESTOR PURCHASE TOKENS
;; ------------------------------------------------------------

(define-public (buy-tokens (quantity uint))
  (begin
    (asserts! (var-get sales-open) (err ERR-SALES-CLOSED))
    (asserts! (<= quantity (var-get remaining-supply)) (err ERR-INSUFFICIENT-TOKENS))

    (let (
          (cost (* quantity (var-get price-per-token)))
          (current-balance (default-to u0 (get amount (map-get? balances { owner: tx-sender }))))
         )

      ;; Transfer payment from investor to farmer
      (try! (stx-transfer? cost tx-sender (var-get farmer)))

      ;; Update investor ledger
      (map-set balances
        { owner: tx-sender }
        { amount: (+ current-balance quantity) })

      ;; Update remaining tokens
      (var-set remaining-supply (- (var-get remaining-supply) quantity))

      (emit-event "tokens-purchased" quantity)
      (ok quantity)
    )
  )
)

;; ------------------------------------------------------------
;; FARMER MARKS HARVEST COMPLETE
;; ------------------------------------------------------------

(define-public (mark-harvest-complete)
  (begin
    (asserts! (is-eq tx-sender (var-get farmer)) (err ERR-NOT-FARMER))
    (asserts! (not (var-get harvest-completed)) (err ERR-HARVEST-ALREADY-COMPLETED))

    (var-set harvest-completed true)
    (var-set sales-open false)

    (emit-event "harvest-completed" u1)
    (ok true)
  )
)

;; ------------------------------------------------------------
;; INVESTOR REDEEM TOKENS AFTER HARVEST
;; (Off-chain produce delivery / payout handled manually)
;; ------------------------------------------------------------

(define-public (redeem-tokens)
  (let (
        (my-balance (default-to u0 (get amount (map-get? balances { owner: tx-sender }))))
       )

    (asserts! (var-get harvest-completed) (err ERR-HARVEST-INCOMPLETE))
    (asserts! (> my-balance u0) (err ERR-NO-TOKENS))

    ;; Burn tokens after redemption
    (map-set balances { owner: tx-sender } { amount: u0 })

    (emit-event "tokens-redeemed" my-balance)
    (ok my-balance)
  )
)

;; ------------------------------------------------------------
;; REFUND INVESTORS IF HARVEST FAILS
;; ------------------------------------------------------------

(define-public (refund)
  (let (
        (my-balance (default-to u0 (get amount (map-get? balances { owner: tx-sender }))))
        (token-price (var-get price-per-token))
       )

    (asserts! (not (var-get harvest-completed)) (err ERR-HARVEST-INCOMPLETE))
    (asserts! (> my-balance u0) (err ERR-NO-TOKENS))

    (let ((refund-amount (* my-balance token-price)))

      ;; Transfer refund from farmer to investor
      (try! (stx-transfer? refund-amount (var-get farmer) tx-sender))

      ;; Burn tokens
      (map-set balances { owner: tx-sender } { amount: u0 })

      (emit-event "refund-issued" refund-amount)
      (ok refund-amount)
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; READ-ONLY FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-balance (user principal))
  (ok (default-to u0 (get amount (map-get? balances { owner: user }))))
)

(define-read-only (get-token-details)
  (ok {
        farmer: (var-get farmer),
        total-supply: (var-get total-supply),
        remaining-supply: (var-get remaining-supply),
        price-per-token: (var-get price-per-token),
        sales-open: (var-get sales-open),
        harvest-completed: (var-get harvest-completed)
      })
)
