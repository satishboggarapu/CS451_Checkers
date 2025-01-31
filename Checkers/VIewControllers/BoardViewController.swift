//
// Created by Satish Boggarapu on 2019-02-05.
// Copyright (c) 2019 SatishBoggarapu. All rights reserved.
//

import UIKit
import SnapKit

class BoardViewController: UIViewController {

    // MARK: UIElements
    private var collectionView: UICollectionView!
    private var topView: UIView!
    private var titleLabel: UILabel!
    private var player1Piece: Piece!
    private var player1Label: UILabel!
    private var player1CounterLabel: UILabel!
    private var player2Piece: Piece!
    private var player2Label: UILabel!
    private var player2CounterLabel: UILabel!
    private var turnLabel: UILabel!
    private var menuButton: UIButton!

    // MARK: Attributes
    private var firebaseGameController: FirebaseGameController!
    private var firebaseReference: FirebaseReference!
    private var game: Game!
    private var selectedIndexPath: IndexPath?
    private var validMoves: [Move]!
    private let boardSize = UIScreen.main.bounds.width - 24
    private var isConnected: Bool = true
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .backgroundColor
        firebaseGameController = FirebaseGameController()
        firebaseReference = FirebaseReference()
        game = Game.getInstance()
        validMoves = [Move]()

        setupView()
        addConstraints()
        refreshGameState()
        
        firebaseGameController.updatePlayerStatus()
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(updateStatusTimerAction), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addValueEventListener()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if game.gameUid != nil {
            firebaseReference.getGameReference(game.gameUid!).removeAllObservers()
        }
        timer = nil
    }

    private func addConstraints() {

        collectionView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(86)
            maker.size.equalTo(boardSize)
        }

        menuButton.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(12)
            maker.right.equalToSuperview().inset(12)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            maker.height.equalTo(52)
        }

        topView.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            maker.bottom.equalTo(collectionView.snp.top).offset(-36)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalToSuperview().offset(8)
            maker.height.equalTo(titleLabel.intrinsicContentSize.height)
        }

        player1Piece.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(16)
            maker.top.equalTo(titleLabel.snp.bottom).offset(24)
            maker.size.equalTo(48)
        }

        player1Label.snp.makeConstraints { maker in
            maker.left.equalTo(player1Piece.snp.right).offset(8)
            maker.right.equalTo(view.snp.centerX)
            maker.top.equalTo(player1Piece.snp.top)
            maker.bottom.equalTo(player1Piece.snp.bottom)
        }

        player1CounterLabel.snp.makeConstraints { maker in
            maker.centerX.equalTo(player1Piece.snp.centerX)
            maker.top.equalTo(player1Piece.snp.bottom).offset(8)
            maker.height.equalTo(player1CounterLabel.intrinsicContentSize.height)
            maker.width.equalTo(50)
        }

        player2Piece.snp.makeConstraints { maker in
            maker.right.equalToSuperview().inset(16)
            maker.top.equalTo(titleLabel.snp.bottom).offset(24)
            maker.size.equalTo(48)
        }

        player2Label.snp.makeConstraints { maker in
            maker.right.equalTo(player2Piece.snp.left).offset(-8)
            maker.left.equalTo(view.snp.centerX)
            maker.top.equalTo(player2Piece.snp.top)
            maker.bottom.equalTo(player2Piece.snp.bottom)
        }

        player2CounterLabel.snp.makeConstraints { maker in
            maker.centerX.equalTo(player2Piece.snp.centerX)
            maker.top.equalTo(player2Piece.snp.bottom).offset(8)
            maker.height.equalTo(player2CounterLabel.intrinsicContentSize.height)
            maker.width.equalTo(50)
        }

        turnLabel.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.bottom.equalToSuperview().inset(24)
            maker.height.equalTo(turnLabel.snp.height)
        }
    }

    private func setupView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(BoardCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.bounces = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.addShadow(cornerRadius: 4, color: UIColor.boardLight.cgColor)
        collectionView.layer.borderWidth = 1
        collectionView.layer.borderColor = UIColor.boardLight.cgColor
        view.addSubview(collectionView)

        topView = UIView()
        topView.backgroundColor = .lightGrayColor
        topView.addShadow(cornerRadius: 4)
        view.addSubview(topView)

        titleLabel = UILabel()
        titleLabel.text = "Checkers"
        titleLabel.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        topView.addSubview(titleLabel)

        player1Piece = Piece(frame: .zero, type: .RED)
        topView.addSubview(player1Piece)

        player1Label = UILabel()
        player1Label.text = game.player1Name
        player1Label.textColor = .white
        player1Label.textAlignment = .left
        player1Label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        topView.addSubview(player1Label)

        player1CounterLabel = UILabel()
        player1CounterLabel.text = "0"
        player1CounterLabel.textColor = .white
        player1CounterLabel.textAlignment = .center
        player1CounterLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        topView.addSubview(player1CounterLabel)

        player2Piece = Piece(frame: .zero, type: .BLUE)
        topView.addSubview(player2Piece)

        player2Label = UILabel()
        player2Label.text = game.player2Name
        player2Label.textColor = .white
        player2Label.textAlignment = .right
        player2Label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        topView.addSubview(player2Label)

        player2CounterLabel = UILabel()
        player2CounterLabel.text = "0"
        player2CounterLabel.textColor = .white
        player2CounterLabel.textAlignment = .center
        player2CounterLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        topView.addSubview(player2CounterLabel)

        turnLabel = UILabel()
        turnLabel.text = game.isPlayer1 ? Message.YOUR_TURN : Message.OPPONENT_TURN
        turnLabel.textColor = .white
        turnLabel.textAlignment = .center
        turnLabel.font = UIFont.systemFont(ofSize: 38, weight: .bold)
        topView.addSubview(turnLabel)

        menuButton = UIButton()
        menuButton.backgroundColor = .highlightColor
        menuButton.setTitle("MENU", for: .normal)
        menuButton.setTitleColor(.white, for: .normal)
        menuButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        menuButton.addTarget(self, action: #selector(menuButtonAction), for: .touchUpInside)
        menuButton.addShadow()
        view.addSubview(menuButton)

    }
    
    @objc private func menuButtonAction() {
        let menuAlert = MenuAlertView()
        menuAlert.delegate = self
        menuAlert.providesPresentationContextTransitionStyle = true
        menuAlert.definesPresentationContext = true
        menuAlert.modalPresentationStyle = .overFullScreen
        menuAlert.modalTransitionStyle = .crossDissolve
        navigationController?.present(menuAlert, animated: true, completion: nil)
    }
    
    @objc private func updateStatusTimerAction() {
        firebaseGameController.updatePlayerStatus()
        if game.isPlayer1 {
            let difference = Date().timeIntervalSince(game.isPlayer2Connected!)
            print(difference)
            if difference > 30 && isConnected {
                self.presentPlayerDisconnected()
                self.isConnected = false
            }
        } else {
            let difference = Date().timeIntervalSince(game.isPlayer1Connected!)
            print(difference)
            if difference > 30 && isConnected {
                self.presentPlayerDisconnected()
                self.isConnected = false
            }
        }
        
    }

    private func refreshGameState() {
        game.refreshGame {
            self.refreshView()
        }
    }
    
    private func isCellInValidMoves(_ indexPath: IndexPath) -> Move? {
        for move in validMoves where move.moveToIndexPath.item == indexPath.item && move.moveToIndexPath.section == indexPath.section {
            return move
        }
        return nil
    }

    private func addValueEventListener() {
        firebaseReference.getGameReference(game.gameUid!).observe(.value) { snapshot in
            if snapshot.exists() {
                self.game.refreshGame(dataSnapshot: snapshot)
                self.refreshView()
            } else {
                let alertView = UIAlertController(title: "Game Over", message: "Your opponent has quit the game.", preferredStyle: .alert)
                
                alertView.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                    self.firebaseGameController.deleteGameFromFirebase(self.game.gameUid!)
                    self.game.resetGame()
                    self.navigationController?.popToRootViewController(animated: false)
                }))
                self.navigationController?.present(alertView, animated: true, completion: nil)
            }
        }
    }

    private func refreshView() {
        player1Label.text = game.player1Name
        player2Label.text = self.game.player2Name
        turnLabel.text = game.isPlayer1 == game.isPlayer1Turn ? Message.YOUR_TURN : Message.OPPONENT_TURN
        player1CounterLabel.text = String(game.board.getPlayer1KillCount())
        player2CounterLabel.text = String(game.board.getPlayer2KillCount())
        collectionView.reloadData()

        switch game.didAPlayerWin() {
        case .PLAYER1:
            presentGameOverAlertDialog(true)
            collectionView.isUserInteractionEnabled = false
        case .PLAYER2:
            presentGameOverAlertDialog(false)
            collectionView.isUserInteractionEnabled = false
        case .TIE:
            ()
        case .GAME_IN_PROGRESS:
            ()
        }
    }

    private func presentGameOverAlertDialog(_ didPlayer1Win: Bool) {
        let message = didPlayer1Win == game.isPlayer1 ? Message.YOU_WIN_MESSAGE : Message.OPPONENT_WIN_MESSAGE
        let alertDialog = UIAlertController(title: "Game Over", message: message, preferredStyle: .alert)

        alertDialog.addAction(UIAlertAction(title: "Ok", style: .default) { action in
            self.firebaseGameController.deleteGameFromFirebase(self.game.gameUid!)
            self.game.resetGame()
            self.navigationController?.popToRootViewController(animated: false)
        })

        navigationController?.present(alertDialog, animated: true)
    }
    
    private func presentPlayerDisconnected() {
        let alertDialog = UIAlertController(title: "Opponent disconnected", message: "Opponent disconnected from the game. Game Over!!", preferredStyle: .alert)
        
        alertDialog.addAction(UIAlertAction(title: "Ok", style: .default) { action in
            self.firebaseGameController.deleteGameFromFirebase(self.game.gameUid!)
            self.game.resetGame()
            self.navigationController?.popToRootViewController(animated: false)
        })
        
        navigationController?.present(alertDialog, animated: true)
    }
}

extension BoardViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 8
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? BoardCollectionViewCell else { return UICollectionViewCell() }

        let sum = indexPath.section + indexPath.item
        if sum % 2 == 0 {
            cell.backgroundColor = .boardDark
        } else {
            cell.backgroundColor = .boardLight
        }

        cell.refreshCell(game.board.getTileForRowCol(row: indexPath.item, col: indexPath.section))
        if let move = isCellInValidMoves(indexPath) {
            cell.highlightCell()
        }

        // Selected Index
        if let selectedIndex = selectedIndexPath, selectedIndex.item == indexPath.item, selectedIndex.section == indexPath.section {
            cell.highlightPiece()
        }

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if game.canPlayerSelectCell(row: indexPath.item, col: indexPath.section) {
            selectedIndexPath = indexPath
            validMoves = game.getPossibleMovesForPiece(row: indexPath.item, col: indexPath.section)
            refreshView()
        } else if let move = isCellInValidMoves(indexPath) {
            game.movePiece(move)
            selectedIndexPath = nil
            validMoves = [Move]()
            game.togglePlayersTurn()
            refreshView()
            firebaseGameController.pushGame()
        } else {
            validMoves = [Move]()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize = boardSize/8.0
        return CGSize(width: cellSize, height: cellSize)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension BoardViewController: MenuAlertViewDelegate {
    func ruleButtonAction() {
        navigationController?.pushViewController(RulesViewController(), animated: true)
    }
    
    func quitGameButtonAction() {
        let alertView = UIAlertController(title: "Quit Game", message: "Are you sure you want to quit the game?", preferredStyle: .alert)
        
        alertView.addAction(UIAlertAction(title: "Quit", style: .default, handler: { action in
            self.navigationController?.popToRootViewController(animated: false)
            self.firebaseGameController.deleteGameFromFirebase(self.game.gameUid!)
            self.game.resetGame()
        }))

        alertView.addAction(UIAlertAction(title: "Cancel", style: .default) { action in
            alertView.dismiss(animated: true)
        })
        
        navigationController?.present(alertView, animated: true, completion: nil)
    }
}
