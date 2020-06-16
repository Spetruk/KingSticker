//
//  TweakViewController.swift
//  Demo
//
//  Created by Purkylin King on 2020/6/9.
//  Copyright © 2020 Purkylin King. All rights reserved.
//

import UIKit

class TweakViewController: UIViewController {
    override func loadView() {
        self.view = TweakView()
    }
}

class TweakView: UIView {
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    var tweaks = [TweakGroup]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadData()
        setupViews()
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(TitleTweakCell.self, forCellReuseIdentifier: TitleTweakCell.reuseIdentifier)
        tableView.register(ToggleTweakCell.self, forCellReuseIdentifier: ToggleTweakCell.reuseIdentifier)
        tableView.register(SliderTweakCell.self, forCellReuseIdentifier: SliderTweakCell.reuseIdentifier)
        tableView.register(StepperTweakCell.self, forCellReuseIdentifier: StepperTweakCell.reuseIdentifier)
        
    }
    
    func setupConstraints() {
        tableView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
    }
    
    func loadData() {
        //        let section = TweakSection(name: "Baby", items: [
        //            TitleTweakItem(name: "Name", value: "Luxi"),
        //            ToggleTweakItem(name: "Sex", value: true),
        //            SliderTweakItem(name: "Age", value: 10, min: 0, max: 100),
        //            StepperTweakItem(name: "Age", value: 1, min: 1, max: 100, step: 1)
        //            ])
        //        self.tweaks = [section]
        self.tweaks = TweakStore.shared.tweaks
    }
}

extension TweakView: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tweaks.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweaks[section].items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tweaks[section].name
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = tweaks[indexPath.section].items[indexPath.row]
        
        if let tweakItem = item as? TitleTweakItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: TitleTweakCell.reuseIdentifier, for: indexPath) as! TitleTweakCell
            cell.set(item: tweakItem)
            return cell
        }
        
        if let tweakItem = item as? ToggleTweakItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: ToggleTweakCell.reuseIdentifier, for: indexPath) as! ToggleTweakCell
            cell.set(item: tweakItem)
            cell.delegate = self
            return cell
        }
        
        if let tweakItem = item as? SliderTweakItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: SliderTweakCell.reuseIdentifier, for: indexPath) as! SliderTweakCell
            cell.set(item: tweakItem)
            return cell
        }
        
        if let tweakItem = item as? StepperTweakItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: StepperTweakCell.reuseIdentifier, for: indexPath) as! StepperTweakCell
            cell.set(item: tweakItem)
            return cell
        }
        
        return UITableViewCell()
    }
}

extension TweakView: TweakCellDelegate {
    func didChanges(for cell: UITableViewCell, value: TweakValueType) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let tweak = tweaks[indexPath.section].items[indexPath.row]
        
    }
    
    func updateChanges() {
        
    }
}

class TitleTweakCell: UITableViewCell {
    static let reuseIdentifier = "tweak_title"
    
    private let label = UILabel()
    private let textField = UITextField()
    private let stackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.selectionStyle = .none
        contentView.addSubview(stackView)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(textField)
        
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 20
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.textAlignment = .right
        
        stackView.pin()
    }
    
    func set(item: TitleTweak) {
        label.text = item.name
        textField.text = item.value
    }
}

protocol TweakCellDelegate: class {
    func didChanges(for cell: UITableViewCell, value: TweakValueType)
}

class SliderTweakCell: UITableViewCell {
    static let reuseIdentifier = "tweak_slider"
    
    weak var delegate: TweakCellDelegate?
    
    private let label = UILabel()
    private let slider = UISlider()
    private let stackView = UIStackView()
    
    private let minLabel = UILabel()
    private let maxLabel = UILabel()
    private let valueLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.selectionStyle = .none
        contentView.addSubview(stackView)
        stackView.addArrangedSubview(label)
        
        let bottomStackView = UIStackView(arrangedSubviews: [minLabel, valueLabel, maxLabel])
        bottomStackView.axis = .horizontal
        bottomStackView.distribution = .equalSpacing
        
        let rightStackView = UIStackView(arrangedSubviews: [slider, bottomStackView])
        rightStackView.axis = .vertical
        stackView.addArrangedSubview(rightStackView)
        
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 20
        
        [minLabel, maxLabel].forEach { $0.font = UIFont.systemFont(ofSize: 12) }
        valueLabel.font = UIFont.boldSystemFont(ofSize: 12)
        
        stackView.pin()
        
        slider.isContinuous = true
        slider.addTarget(self, action: #selector(onChanged), for: .valueChanged)
    }
    
    @objc func onChanged(_ sender: UISlider) {
        let value = String(format: "%.2f", sender.value)
        valueLabel.text = value
        
        delegate?.didChanges(for: self, value: value)
    }
    
    func set(item: SliderTweak) {
        label.text = item.name
        slider.minimumValue = Float(item.min)
        slider.maximumValue = Float(item.max)
        slider.value = Float(item.value)
        
        minLabel.text = "\(item.min)"
        maxLabel.text = "\(item.max)"
        valueLabel.text = "\(item.value)"
    }
}

class StepperTweakCell: UITableViewCell {
    static let reuseIdentifier = "tweak_stepper"
    
    private let label = UILabel()
    private let stepper = UIStepper()
    private let stackView = UIStackView()
    
    private let valueLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.selectionStyle = .none
        contentView.addSubview(stackView)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(valueLabel)
        stackView.addArrangedSubview(stepper)
        
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 20
        stackView.alignment = .center
        
        valueLabel.font = UIFont.boldSystemFont(ofSize: 12)
        
        stackView.pin()
        stepper.addTarget(self, action: #selector(onChanged), for: .valueChanged)
    }
    
    @objc func onChanged(_ sender: UIStepper) {
        let value = Int(sender.value)
        valueLabel.text = "\(value)"
    }
    
    func set(item: StepperTweak) {
        label.text = item.name
        stepper.minimumValue = Double(item.min)
        stepper.maximumValue = Double(item.max)
        stepper.stepValue = Double(item.step)
        stepper.value = Double(item.value)
        valueLabel.text = "\(item.value)"
    }
}

class ToggleTweakCell: UITableViewCell {
    static let reuseIdentifier = "tweak_toggle"
    
    weak var delegate: TweakCellDelegate?
    
    private let label = UILabel()
    private let statusSwitch = UISwitch()
    private let stackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.selectionStyle = .none
        contentView.addSubview(stackView)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(statusSwitch)
        
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 20
        
        stackView.pin()
        statusSwitch.addTarget(self, action: #selector(onChanged), for: .valueChanged)
    }
    
    @objc func onChanged(_ sender: UISwitch) {
        delegate?.didChanges(for: self, value: sender.isOn)
    }
    
    func set(item: ToggleTweak) {
        label.text = item.name
        statusSwitch.isOn = item.value
    }
}

extension UIView {
    func pin() {
        guard let parent = self.superview else { return }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: parent.topAnchor).isActive = true
        self.rightAnchor.constraint(equalTo: parent.layoutMarginsGuide.rightAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: parent.bottomAnchor).isActive = true
        self.leftAnchor.constraint(equalTo: parent.layoutMarginsGuide.leftAnchor).isActive = true
    }
}


