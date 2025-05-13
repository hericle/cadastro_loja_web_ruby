
require 'sinatra'
require 'erb'

enable :sessions

class Usuario
  attr_reader :nome, :email, :senha, :tipo

  def initialize(nome, email, senha, tipo)
    @nome = nome
    @email = email
    @senha = senha
    @tipo = tipo
  end

  def verificar_senha(senha)
    @senha == senha
  end
end

USUARIOS = {}
USUARIOS['admin@admin.com'] = Usuario.new('Administrador', 'admin@admin.com', 'admin123', 'adm')

helpers do
  def logado?
    !!session[:usuario]
  end

  def usuario_atual
    USUARIOS[session[:usuario]]
  end

  def admin?
    usuario_atual&.tipo == 'adm'
  end
end

get '/' do
  redirect '/login'
end

get '/login' do
  erb :login
end

post '/login' do
  email = params[:email]
  senha = params[:senha]
  usuario = USUARIOS[email]

  if usuario && usuario.verificar_senha(senha)
    session[:usuario] = email
    redirect '/painel'
  else
    @erro = 'Email ou senha incorretos.'
    erb :login
  end
end

get '/painel' do
  redirect '/login' unless logado?
  erb admin? ? :painel_admin : :painel_cliente
end

get '/logout' do
  session.clear
  redirect '/login'
end

get '/admin/cadastrar_cliente' do
  if !logado?
    redirect '/login'
  elsif !admin?
    @erro = "Acesso negado: somente administradores podem acessar esta página."
    return erb admin? ? :painel_admin : :painel_cliente
  end

  erb :cadastro_cliente
end

post '/admin/cadastrar_cliente' do
  if !logado?
    redirect '/login'
  elsif !admin?
    @erro = "Acesso negado: somente administradores podem realizar esta ação."
    return erb admin? ? :painel_admin : :painel_cliente
  end

  nome = params[:nome]
  email = params[:email]
  senha = params[:senha]

  if USUARIOS.key?(email)
    @erro = 'Email já cadastrado.'
  else
    USUARIOS[email] = Usuario.new(nome, email, senha, 'cliente')
    @sucesso = 'Cliente cadastrado com sucesso!'
  end

  erb :cadastro_cliente
end

get '/admin/clientes' do
  redirect '/login' unless logado?
  unless admin?
    @erro = "Acesso negado: somente administradores podem acessar esta página."
    return erb :painel_cliente
  end

  @clientes = USUARIOS.values.select { |u| u.tipo == 'cliente' }
  erb :lista_clientes
end
