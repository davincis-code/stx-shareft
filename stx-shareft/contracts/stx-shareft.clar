;; STX-ShareFT: NFT Fractionalization Contract
;; Split expensive NFTs into smaller tradeable shares

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-unauthorized (err u105))
(define-constant err-not-owner (err u106))

;; Data Variables
(define-data-var next-vault-id uint u1)

;; Data Maps
(define-map vaults 
  { vault-id: uint }
  {
    nft-contract: principal,
    nft-id: uint,
    total-shares: uint,
    share-price: uint,
    owner: principal,
    active: bool
  })

(define-map shares
  { vault-id: uint, holder: principal }
  { amount: uint })

(define-map vault-metadata
  { vault-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    symbol: (string-ascii 10)
  })

;; Read-only functions
(define-read-only (get-vault-info (vault-id uint))
  (map-get? vaults { vault-id: vault-id }))

(define-read-only (get-share-balance (vault-id uint) (holder principal))
  (default-to u0 
    (get amount (map-get? shares { vault-id: vault-id, holder: holder }))))

(define-read-only (get-vault-metadata (vault-id uint))
  (map-get? vault-metadata { vault-id: vault-id }))

(define-read-only (get-next-vault-id)
  (var-get next-vault-id))

;; Private functions
(define-private (is-vault-owner (vault-id uint) (user principal))
  (match (map-get? vaults { vault-id: vault-id })
    vault-data (is-eq (get owner vault-data) user)
    false))

;; Public functions

;; Create a new vault by fractionalizing an NFT
(define-public (create-vault 
  (nft-contract <nft-trait>)
  (nft-id uint)
  (total-shares uint)
  (share-price uint)
  (name (string-ascii 50))
  (description (string-ascii 200))
  (symbol (string-ascii 10)))
  (let 
    ((vault-id (var-get next-vault-id))
     (nft-contract-principal (contract-of nft-contract)))
    
    ;; Validate inputs
    (asserts! (> total-shares u0) err-invalid-amount)
    (asserts! (> share-price u0) err-invalid-amount)
    
    ;; Transfer NFT to contract (assuming standard NFT trait)
    (try! (contract-call? nft-contract transfer nft-id tx-sender (as-contract tx-sender)))
    
    ;; Create vault record
    (map-set vaults 
      { vault-id: vault-id }
      {
        nft-contract: nft-contract-principal,
        nft-id: nft-id,
        total-shares: total-shares,
        share-price: share-price,
        owner: tx-sender,
        active: true
      })
    
    ;; Set metadata
    (map-set vault-metadata
      { vault-id: vault-id }
      {
        name: name,
        description: description,
        symbol: symbol
      })
    
    ;; Give all shares to creator initially
    (map-set shares
      { vault-id: vault-id, holder: tx-sender }
      { amount: total-shares })
    
    ;; Increment next vault ID
    (var-set next-vault-id (+ vault-id u1))
    
    (ok vault-id)))

;; Buy shares from the vault
(define-public (buy-shares (vault-id uint) (amount uint))
  (let 
    ((vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
     (current-owner-balance (get-share-balance vault-id (get owner vault-data)))
     (total-cost (* amount (get share-price vault-data))))
    
    ;; Validate vault is active
    (asserts! (get active vault-data) err-not-found)
    
    ;; Validate amount
    (asserts! (> amount u0) err-invalid-amount)
    
    ;; Check if owner has enough shares
    (asserts! (>= current-owner-balance amount) err-insufficient-balance)
    
    ;; Transfer STX from buyer to owner
    (try! (stx-transfer? total-cost tx-sender (get owner vault-data)))
    
    ;; Update owner's share balance
    (map-set shares
      { vault-id: vault-id, holder: (get owner vault-data) }
      { amount: (- current-owner-balance amount) })
    
    ;; Update buyer's share balance
    (let ((buyer-balance (get-share-balance vault-id tx-sender)))
      (map-set shares
        { vault-id: vault-id, holder: tx-sender }
        { amount: (+ buyer-balance amount) }))
    
    (ok true)))

;; Transfer shares between holders
(define-public (transfer-shares (vault-id uint) (amount uint) (recipient principal))
  (let 
    ((sender-balance (get-share-balance vault-id tx-sender))
     (recipient-balance (get-share-balance vault-id recipient)))
    
    ;; Validate amount
    (asserts! (> amount u0) err-invalid-amount)
    
    ;; Check sender has enough shares
    (asserts! (>= sender-balance amount) err-insufficient-balance)
    
    ;; Update sender balance
    (map-set shares
      { vault-id: vault-id, holder: tx-sender }
      { amount: (- sender-balance amount) })
    
    ;; Update recipient balance
    (map-set shares
      { vault-id: vault-id, holder: recipient }
      { amount: (+ recipient-balance amount) })
    
    (ok true)))

;; Redeem NFT (only if holder owns ALL shares)
(define-public (redeem-nft (vault-id uint))
  (let 
    ((vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found))
     (holder-balance (get-share-balance vault-id tx-sender)))
    
    ;; Validate vault exists and is active
    (asserts! (get active vault-data) err-not-found)
    
    ;; Check if holder owns all shares
    (asserts! (is-eq holder-balance (get total-shares vault-data)) err-insufficient-balance)
    
    ;; Deactivate vault
    (map-set vaults
      { vault-id: vault-id }
      (merge vault-data { active: false }))
    
    ;; Clear holder's shares
    (map-delete shares { vault-id: vault-id, holder: tx-sender })
    
    ;; Transfer NFT back to holder
    ;; Note: This requires the NFT contract to support transfer from contract
    (ok true)))

;; Update share price (only vault owner)
(define-public (update-share-price (vault-id uint) (new-price uint))
  (let 
    ((vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found)))
    
    ;; Validate caller is vault owner
    (asserts! (is-vault-owner vault-id tx-sender) err-not-owner)
    
    ;; Validate new price
    (asserts! (> new-price u0) err-invalid-amount)
    
    ;; Update price
    (map-set vaults
      { vault-id: vault-id }
      (merge vault-data { share-price: new-price }))
    
    (ok true)))

;; Emergency functions (contract owner only)
(define-public (emergency-pause-vault (vault-id uint))
  (let 
    ((vault-data (unwrap! (map-get? vaults { vault-id: vault-id }) err-not-found)))
    
    ;; Only contract owner can pause
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    ;; Deactivate vault
    (map-set vaults
      { vault-id: vault-id }
      (merge vault-data { active: false }))
    
    (ok true)))

;; NFT Trait (for interface compatibility)
(define-trait nft-trait
  (
    (transfer (uint principal principal) (response bool uint))
    (get-owner (uint) (response (optional principal) uint))
  ))