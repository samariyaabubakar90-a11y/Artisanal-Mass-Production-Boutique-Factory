;; title: machine-learning-grandmother-recipe-simulator
;; version: 1.0.0
;; summary: Teaches AI to code with the same love and attention as traditional home cooking
;; description: Captures grandmother's wisdom and translates it into scalable algorithms

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_RECIPE_NOT_FOUND (err u101))
(define-constant ERR_INVALID_INGREDIENT (err u102))
(define-constant ERR_INSUFFICIENT_WISDOM (err u103))
(define-constant ERR_RECIPE_ALREADY_EXISTS (err u104))
(define-constant ERR_INVALID_PORTION_SIZE (err u105))

;; Maximum values for validation
(define-constant MAX_RECIPE_NAME_LENGTH u100)
(define-constant MAX_INGREDIENT_COUNT u50)
(define-constant MAX_WISDOM_SCORE u100)
(define-constant MIN_COOKING_TIME u1)
(define-constant MAX_COOKING_TIME u1440) ;; 24 hours in minutes

;; Data Variables
(define-data-var recipe-counter uint u0)
(define-data-var total-wisdom-collected uint u0)
(define-data-var active-recipe-count uint u0)

;; Data Maps
;; Store recipe details with grandmother's wisdom embedded
(define-map recipes
    { recipe-id: uint }
    {
        name: (string-ascii 100),
        creator: principal,
        wisdom-score: uint,
        ingredient-count: uint,
        cooking-time-minutes: uint,
        love-factor: uint,
        tradition-weight: uint,
        created-at: uint,
        is-active: bool
    }
)

;; Store individual ingredients with their grandmother-approved properties
(define-map recipe-ingredients
    { recipe-id: uint, ingredient-index: uint }
    {
        ingredient-name: (string-ascii 50),
        quantity: uint,
        unit: (string-ascii 20),
        preparation-method: (string-ascii 100),
        emotional-significance: uint,
        seasonal-availability: uint
    }
)

;; Store cooking instructions with embedded wisdom
(define-map cooking-instructions
    { recipe-id: uint, step-number: uint }
    {
        instruction: (string-ascii 200),
        timing: uint,
        temperature: uint,
        intuition-level: uint,
        grandmother-notes: (string-ascii 150)
    }
)

;; Track wisdom contributions from different sources
(define-map wisdom-contributors
    { contributor: principal }
    {
        total-recipes: uint,
        wisdom-points: uint,
        grandmother-certification: bool,
        last-contribution: uint
    }
)

;; Store machine learning parameters for recipe optimization
(define-map ml-parameters
    { recipe-id: uint }
    {
        taste-prediction-score: uint,
        difficulty-rating: uint,
        success-probability: uint,
        personalization-factor: uint,
        cultural-authenticity: uint
    }
)

;; Private Functions

;; Calculate wisdom score based on multiple factors
(define-private (calculate-wisdom-score (love-factor uint) (tradition-weight uint) (cooking-time uint))
    (let (
        (base-score (+ love-factor tradition-weight))
        (time-bonus (if (>= cooking-time u60) u10 u0))
        (tradition-bonus (if (>= tradition-weight u80) u15 u5))
    )
    (if (<= (+ base-score time-bonus tradition-bonus) MAX_WISDOM_SCORE)
        (+ base-score time-bonus tradition-bonus)
        MAX_WISDOM_SCORE)
    )
)

;; Validate ingredient properties
(define-private (validate-ingredient (name (string-ascii 50)) (quantity uint) (emotional-significance uint))
    (and
        (> (len name) u0)
        (> quantity u0)
        (<= emotional-significance u100)
    )
)

;; Calculate recipe complexity based on ingredients and instructions
(define-private (calculate-complexity (ingredient-count uint) (total-steps uint) (max-cooking-time uint))
    (let (
        (ingredient-complexity (* ingredient-count u2))
        (step-complexity total-steps)
        (time-complexity (/ max-cooking-time u30))
    )
    (+ ingredient-complexity step-complexity time-complexity)
    )
)

;; Update contributor wisdom points
(define-private (update-wisdom-contributor (contributor principal) (wisdom-gained uint))
    (let (
        (current-data (default-to 
            { total-recipes: u0, wisdom-points: u0, grandmother-certification: false, last-contribution: u0 }
            (map-get? wisdom-contributors { contributor: contributor })
        ))
    )
    (map-set wisdom-contributors
        { contributor: contributor }
        {
            total-recipes: (+ (get total-recipes current-data) u1),
            wisdom-points: (+ (get wisdom-points current-data) wisdom-gained),
            grandmother-certification: (>= (+ (get wisdom-points current-data) wisdom-gained) u500),
            last-contribution: stacks-block-height
        }
    )
    )
)

;; Public Functions

;; Create a new grandmother-inspired recipe
(define-public (create-recipe 
    (name (string-ascii 100))
    (cooking-time-minutes uint)
    (love-factor uint)
    (tradition-weight uint)
)
    (let (
        (recipe-id (+ (var-get recipe-counter) u1))
        (wisdom-score (calculate-wisdom-score love-factor tradition-weight cooking-time-minutes))
    )
    (asserts! (> (len name) u0) ERR_RECIPE_NOT_FOUND)
    (asserts! (and (>= cooking-time-minutes MIN_COOKING_TIME) (<= cooking-time-minutes MAX_COOKING_TIME)) ERR_INVALID_PORTION_SIZE)
    (asserts! (and (> love-factor u0) (<= love-factor u100)) ERR_INVALID_INGREDIENT)
    (asserts! (and (> tradition-weight u0) (<= tradition-weight u100)) ERR_INVALID_INGREDIENT)
    
    ;; Create the recipe
    (map-set recipes
        { recipe-id: recipe-id }
        {
            name: name,
            creator: tx-sender,
            wisdom-score: wisdom-score,
            ingredient-count: u0,
            cooking-time-minutes: cooking-time-minutes,
            love-factor: love-factor,
            tradition-weight: tradition-weight,
            created-at: stacks-block-height,
            is-active: true
        }
    )
    
    ;; Update global counters
    (var-set recipe-counter recipe-id)
    (var-set active-recipe-count (+ (var-get active-recipe-count) u1))
    (var-set total-wisdom-collected (+ (var-get total-wisdom-collected) wisdom-score))
    
    ;; Update contributor data
    (update-wisdom-contributor tx-sender wisdom-score)
    
    (ok recipe-id)
    )
)

;; Add ingredient to a recipe with grandmother's wisdom
(define-public (add-ingredient
    (recipe-id uint)
    (ingredient-name (string-ascii 50))
    (quantity uint)
    (unit (string-ascii 20))
    (preparation-method (string-ascii 100))
    (emotional-significance uint)
    (seasonal-availability uint)
)
    (let (
        (recipe-data (unwrap! (map-get? recipes { recipe-id: recipe-id }) ERR_RECIPE_NOT_FOUND))
        (current-ingredient-count (get ingredient-count recipe-data))
        (new-ingredient-index (+ current-ingredient-count u1))
    )
    ;; Validate ownership or authorization
    (asserts! (or (is-eq tx-sender (get creator recipe-data)) (is-eq tx-sender CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
    (asserts! (validate-ingredient ingredient-name quantity emotional-significance) ERR_INVALID_INGREDIENT)
    (asserts! (< current-ingredient-count MAX_INGREDIENT_COUNT) ERR_INVALID_INGREDIENT)
    (asserts! (get is-active recipe-data) ERR_RECIPE_NOT_FOUND)
    
    ;; Add the ingredient
    (map-set recipe-ingredients
        { recipe-id: recipe-id, ingredient-index: new-ingredient-index }
        {
            ingredient-name: ingredient-name,
            quantity: quantity,
            unit: unit,
            preparation-method: preparation-method,
            emotional-significance: emotional-significance,
            seasonal-availability: seasonal-availability
        }
    )
    
    ;; Update recipe ingredient count
    (map-set recipes
        { recipe-id: recipe-id }
        (merge recipe-data { ingredient-count: new-ingredient-index })
    )
    
    (ok new-ingredient-index)
    )
)

;; Add cooking instruction with grandmother's intuition
(define-public (add-cooking-instruction
    (recipe-id uint)
    (step-number uint)
    (instruction (string-ascii 200))
    (timing uint)
    (temperature uint)
    (intuition-level uint)
    (grandmother-notes (string-ascii 150))
)
    (let (
        (recipe-data (unwrap! (map-get? recipes { recipe-id: recipe-id }) ERR_RECIPE_NOT_FOUND))
    )
    ;; Validate ownership or authorization
    (asserts! (or (is-eq tx-sender (get creator recipe-data)) (is-eq tx-sender CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
    (asserts! (get is-active recipe-data) ERR_RECIPE_NOT_FOUND)
    (asserts! (> (len instruction) u0) ERR_INVALID_INGREDIENT)
    (asserts! (<= intuition-level u100) ERR_INVALID_INGREDIENT)
    
    ;; Add the cooking instruction
    (map-set cooking-instructions
        { recipe-id: recipe-id, step-number: step-number }
        {
            instruction: instruction,
            timing: timing,
            temperature: temperature,
            intuition-level: intuition-level,
            grandmother-notes: grandmother-notes
        }
    )
    
    (ok step-number)
    )
)

;; Read-only Functions

;; Get recipe details
(define-read-only (get-recipe (recipe-id uint))
    (map-get? recipes { recipe-id: recipe-id })
)

;; Get recipe ingredient
(define-read-only (get-recipe-ingredient (recipe-id uint) (ingredient-index uint))
    (map-get? recipe-ingredients { recipe-id: recipe-id, ingredient-index: ingredient-index })
)

;; Get cooking instruction
(define-read-only (get-cooking-instruction (recipe-id uint) (step-number uint))
    (map-get? cooking-instructions { recipe-id: recipe-id, step-number: step-number })
)

;; Get contributor wisdom data
(define-read-only (get-wisdom-contributor (contributor principal))
    (map-get? wisdom-contributors { contributor: contributor })
)

;; Get current statistics
(define-read-only (get-contract-stats)
    {
        total-recipes: (var-get recipe-counter),
        active-recipes: (var-get active-recipe-count),
        total-wisdom: (var-get total-wisdom-collected)
    }
)

;; Calculate recipe recommendation score based on ML parameters
(define-public (calculate-recommendation-score (recipe-id uint) (user-preferences uint))
    (let (
        (recipe-data (unwrap! (map-get? recipes { recipe-id: recipe-id }) ERR_RECIPE_NOT_FOUND))
        (ml-data (default-to 
            { taste-prediction-score: u50, difficulty-rating: u50, success-probability: u50, personalization-factor: u50, cultural-authenticity: u50 }
            (map-get? ml-parameters { recipe-id: recipe-id })
        ))
    )
    (let (
        (wisdom-bonus (* (get wisdom-score recipe-data) u2))
        (taste-score (get taste-prediction-score ml-data))
        (personalization-match (- u100 (if (> user-preferences (get personalization-factor ml-data))
            (- user-preferences (get personalization-factor ml-data))
            (- (get personalization-factor ml-data) user-preferences))))
        (final-score (/ (+ wisdom-bonus taste-score personalization-match) u3))
    )
    (ok final-score)
    )
    )
)

;; Set ML parameters for a recipe (only recipe creator or contract owner)
(define-public (set-ml-parameters
    (recipe-id uint)
    (taste-prediction-score uint)
    (difficulty-rating uint)
    (success-probability uint)
    (personalization-factor uint)
    (cultural-authenticity uint)
)
    (let (
        (recipe-data (unwrap! (map-get? recipes { recipe-id: recipe-id }) ERR_RECIPE_NOT_FOUND))
    )
    (asserts! (or (is-eq tx-sender (get creator recipe-data)) (is-eq tx-sender CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
    (asserts! (get is-active recipe-data) ERR_RECIPE_NOT_FOUND)
    
    (map-set ml-parameters
        { recipe-id: recipe-id }
        {
            taste-prediction-score: taste-prediction-score,
            difficulty-rating: difficulty-rating,
            success-probability: success-probability,
            personalization-factor: personalization-factor,
            cultural-authenticity: cultural-authenticity
        }
    )
    
    (ok true)
    )
)
